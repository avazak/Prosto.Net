import 'dart:async';
import 'package:flutter/services.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';

class AmneziaVpnService {
  static const MethodChannel _channel = MethodChannel('com.example.prosto_net/amnezia_vpn');
  
  static VpnStatusInfo _currentStatus = VpnStatusInfo(
    status: VpnStatus.disconnected,
    lastUpdated: DateTime.now(),
  );

  static final StreamController<VpnStatusInfo> _statusController = StreamController<VpnStatusInfo>.broadcast();
  static Stream<VpnStatusInfo> get statusStream => _statusController.stream;

  static VpnStatusInfo get currentStatus => _currentStatus;

  static bool _isInitialized = false;

  // Initialize the service and set up method call handler
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;

    // Get initial status
    await _updateStatusFromNative();
  }

  // Handle method calls from native side
  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStatusChanged':
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        _handleStatusUpdate(data);
        break;
    }
  }

  // Handle status updates from native side
  static void _handleStatusUpdate(Map<String, dynamic> data) {
    final statusString = data['status'] as String?;
    final configName = data['configName'] as String?;
    final errorMessage = data['errorMessage'] as String?;
    final timestamp = data['timestamp'] as int?;

    VpnStatus status;
    switch (statusString) {
      case 'connecting':
        status = VpnStatus.connecting;
        break;
      case 'connected':
        status = VpnStatus.connected;
        break;
      case 'disconnecting':
        status = VpnStatus.disconnecting;
        break;
      case 'error':
        status = VpnStatus.error;
        break;
      default:
        status = VpnStatus.disconnected;
    }

    _currentStatus = VpnStatusInfo(
      status: status,
      errorMessage: errorMessage,
      lastUpdated: timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : DateTime.now(),
      connectedConfig: configName,
    );

    _statusController.add(_currentStatus);
  }

  // Start VPN connection
  static Future<bool> startVpn(VpnConfig config) async {
    try {
      await initialize();
      
      final result = await _channel.invokeMethod('startVpn', {
        'configData': config.configData,
        'configName': config.name,
      });
      
      return result == true;
    } catch (e) {
      _updateStatus(VpnStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  // Stop VPN connection
  static Future<bool> stopVpn() async {
    try {
      await initialize();
      
      final result = await _channel.invokeMethod('stopVpn');
      return result == true;
    } catch (e) {
      _updateStatus(VpnStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  // Get current VPN status
  static Future<VpnStatusInfo> getStatus() async {
    try {
      await initialize();
      await _updateStatusFromNative();
      return _currentStatus;
    } catch (e) {
      return VpnStatusInfo(
        status: VpnStatus.error,
        errorMessage: e.toString(),
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Get VPN statistics
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      await initialize();
      
      final result = await _channel.invokeMethod('getVpnStats');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error getting VPN stats: $e');
      return null;
    }
  }

  // Update status from native side
  static Future<void> _updateStatusFromNative() async {
    try {
      final result = await _channel.invokeMethod('getVpnStatus');
      final data = Map<String, dynamic>.from(result);
      _handleStatusUpdate(data);
    } catch (e) {
      print('Error updating status from native: $e');
    }
  }

  // Update status locally
  static void _updateStatus(VpnStatus status, {String? errorMessage, String? connectedConfig}) {
    _currentStatus = VpnStatusInfo(
      status: status,
      errorMessage: errorMessage,
      lastUpdated: DateTime.now(),
      connectedConfig: connectedConfig,
    );
    
    _statusController.add(_currentStatus);
  }

  // Dispose resources
  static void dispose() {
    _statusController.close();
    _isInitialized = false;
  }
}

