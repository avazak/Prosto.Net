package com.example.prosto_net

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.util.Log
import kotlinx.coroutines.*
import org.amnezia.awg.backend.Backend
import org.amnezia.awg.backend.Tunnel
import org.amnezia.awg.backend.GoBackend
import org.amnezia.awg.backend.Statistics
import org.amnezia.awg.config.Config
import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.os.SystemClock

class AmneziaVpnPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var vpnScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // VPN state management
    private var isVpnConnected = false
    private var isVpnConnecting = false
    private var currentConfigName: String? = null
    private var lastError: String? = null

    // AmneziaWG backend instance
    private var goBackend: GoBackend? = null
    private var currentTunnel: Tunnel? = null

    // Добавим поле для отслеживания времени старта VPN
    private var vpnStartTimestamp: Long? = null

    // Для хранения последних данных при повторном запуске после разрешения
    private var lastConfigData: String? = null
    private var lastConfigName: String? = null

    // Код запроса разрешения на VPN
    private val VPN_REQUEST_CODE = 1001

    // Активити для запроса разрешения
    private var activity: Activity? = null
    private var pendingVpnResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.prosto_net/amnezia_vpn")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        goBackend = GoBackend(context)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            if (requestCode == VPN_REQUEST_CODE) {
                if (resultCode == Activity.RESULT_OK) {
                    // Разрешение получено, повторяем запуск VPN
                    val lastResult = pendingVpnResult
                    pendingVpnResult = null
                    if (lastResult != null && lastConfigData != null && lastConfigName != null) {
                        startVpnInternal(lastConfigData!!, lastConfigName!!, lastResult, skipPrepare = true)
                    }
                } else {
                    pendingVpnResult?.error("VPN_PERMISSION_DENIED", "Пользователь не дал разрешение на VPN", null)
                    pendingVpnResult = null
                }
                true
            } else {
                false
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVpn" -> {
                val configData = call.argument<String>("configData")
                val configName = call.argument<String>("configName")
                if (configData != null && configName != null) {
                    startVpn(configData, configName, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Config data and name are required", null)
                }
            }
            "stopVpn" -> {
                stopVpn(result)
            }
            "getVpnStatus" -> {
                getVpnStatus(result)
            }
            "getVpnStats" -> {
                getVpnStats(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startVpn(configData: String, configName: String, result: MethodChannel.Result) {
        if (isVpnConnecting || isVpnConnected) {
            result.error("VPN_BUSY", "VPN is already connecting or connected", null)
            return
        }
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity is not attached", null)
            return
        }
        val intent = VpnService.prepare(act)
        if (intent != null) {
            // Нужно запросить разрешение
            pendingVpnResult = result
            lastConfigData = configData
            lastConfigName = configName
            act.startActivityForResult(intent, VPN_REQUEST_CODE)
            return
        }
        // Разрешение уже есть
        startVpnInternal(configData, configName, result, skipPrepare = true)
    }

    private fun startVpnInternal(configData: String, configName: String, result: MethodChannel.Result, skipPrepare: Boolean = false) {
        vpnScope.launch {
            try {
                isVpnConnecting = true
                lastError = null
                notifyStatusChange("connecting")

                Log.d("AmneziaVpnPlugin", "Starting VPN tunnel with config: $configData")
                val backend = goBackend ?: throw Exception("GoBackend not initialized")
                val config = Config.parse(configData.byteInputStream())
                val tunnel = object : Tunnel {
                    override fun getName() = configName
                    override fun onStateChange(state: Tunnel.State) {
                        Log.d("AmneziaVpnPlugin", "Tunnel state changed: $state")
                    }
                }

                // Явно стартуем сервис VpnService и ждём его готовности
                val ctx = activity ?: context
                val serviceIntent = Intent(ctx, GoBackend.VpnService::class.java)
                ctx.startService(serviceIntent)
                // Ждём, пока сервис не станет доступен (макс. 2 сек)
                var serviceReady = false
                val startTime = SystemClock.elapsedRealtime()
                while (SystemClock.elapsedRealtime() - startTime < 2000) {
                    try {
                        // Проверяем через рефлексию static поле vpnService.isDone()
                        val vpnServiceField = GoBackend::class.java.getDeclaredField("vpnService")
                        vpnServiceField.isAccessible = true
                        val vpnServiceObj = vpnServiceField.get(null)
                        val isDoneMethod = vpnServiceObj.javaClass.getMethod("isDone")
                        val isDone = isDoneMethod.invoke(vpnServiceObj) as Boolean
                        if (isDone) {
                            serviceReady = true
                            break
                        }
                    } catch (e: Exception) {
                        Log.e("AmneziaVpnPlugin", "Error checking VpnService readiness", e)
                    }
                    delay(100)
                }
                if (!serviceReady) {
                    throw Exception("VpnService не стартовал")
                }

                Log.d("AmneziaVpnPlugin", "VpnService is ready, setting tunnel state to UP")
                backend.setState(tunnel, Tunnel.State.UP, config)

                Log.d("AmneziaVpnPlugin", "VPN tunnel is now active")
                isVpnConnected = true
                isVpnConnecting = false
                currentConfigName = configName
                currentTunnel = tunnel
                vpnStartTimestamp = System.currentTimeMillis()
                notifyStatusChange("connected")
                result.success(true)
            } catch (e: Exception) {
                Log.e("AmneziaVpnPlugin", "Failed to start VPN", e)
                isVpnConnecting = false
                isVpnConnected = false
                lastError = e.message
                notifyStatusChange("error")
                result.error("VPN_START_FAILED", e.message, null)
            }
        }
    }

    private fun stopVpn(result: MethodChannel.Result) {
        if (!isVpnConnected && !isVpnConnecting) {
            result.error("VPN_NOT_CONNECTED", "VPN is not connected", null)
            return
        }

        vpnScope.launch {
            try {
                notifyStatusChange("disconnecting")
                val backend = goBackend
                val tunnel = currentTunnel
                if (backend != null && tunnel != null) {
                    backend.setState(tunnel, Tunnel.State.DOWN, null)
                }
                isVpnConnected = false
                isVpnConnecting = false
                currentConfigName = null
                currentTunnel = null
                lastError = null
                vpnStartTimestamp = null
                notifyStatusChange("disconnected")
                result.success(true)
            } catch (e: Exception) {
                Log.e("AmneziaVpnPlugin", "Failed to stop VPN", e)
                lastError = e.message
                notifyStatusChange("error")
                result.error("VPN_STOP_FAILED", e.message, null)
            }
        }
    }

    private fun getVpnStatus(result: MethodChannel.Result) {
        val status = when {
            isVpnConnecting -> "connecting"
            isVpnConnected -> "connected"
            lastError != null -> "error"
            else -> "disconnected"
        }
        
        val statusMap = mapOf(
            "status" to status,
            "configName" to currentConfigName,
            "errorMessage" to lastError,
            "lastUpdated" to System.currentTimeMillis()
        )
        
        result.success(statusMap)
    }

    private fun getVpnStats(result: MethodChannel.Result) {
        if (!isVpnConnected) {
            result.error("VPN_NOT_CONNECTED", "VPN is not connected", null)
            return
        }

        vpnScope.launch {
            try {
                val backend = goBackend
                val tunnel = currentTunnel
                if (backend != null && tunnel != null) {
                    val stats = backend.getStatistics(tunnel)
                    val peers = stats.peers()
                    var bytesIn: Long = 0
                    var bytesOut: Long = 0
                    for (peer in peers) {
                        val peerStats = stats.peer(peer)
                        bytesIn += peerStats?.rxBytes ?: 0
                        bytesOut += peerStats?.txBytes ?: 0
                    }
                    val lastUpdated = System.currentTimeMillis()
                    val connectionDuration = lastUpdated - (vpnStartTimestamp ?: lastUpdated)
                    val statsMap = mapOf(
                        "bytesIn" to bytesIn,
                        "bytesOut" to bytesOut,
                        "connectionDuration" to connectionDuration
                    )
                    result.success(statsMap)
                } else {
                    result.error("VPN_NOT_CONNECTED", "No active tunnel", null)
                }
            } catch (e: Exception) {
                Log.e("AmneziaVpnPlugin", "Failed to get VPN stats", e)
                result.error("VPN_STATS_FAILED", e.message, null)
            }
        }
    }

    private fun notifyStatusChange(status: String) {
        val statusData = mapOf(
            "status" to status,
            "configName" to currentConfigName,
            "errorMessage" to lastError,
            "timestamp" to System.currentTimeMillis()
        )
        
        channel.invokeMethod("onStatusChanged", statusData)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        vpnScope.cancel()
    }
}
