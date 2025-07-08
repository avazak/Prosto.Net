import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';
import '../services/amnezia_vpn_service.dart';
import '../services/config_service.dart';
import '../widgets/config_list_item.dart';
import '../widgets/vpn_status_card.dart';
import 'config_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VpnConfig> _configs = [];
  VpnStatusInfo _vpnStatus = AmneziaVpnService.currentStatus;
  VpnConfig? _activeConfig;
  StreamSubscription<VpnStatusInfo>? _statusSubscription;
  Timer? _statsTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await AmneziaVpnService.initialize();
    await _loadConfigs();
    _startStatusUpdates();
    _startStatsUpdates();
  }

  Future<void> _loadConfigs() async {
    try {
      final configs = await ConfigService.loadConfigs();
      final activeConfig = await ConfigService.getActiveConfig();
      
      setState(() {
        _configs = configs;
        _activeConfig = activeConfig;
      });
    } catch (e) {
      print('Error loading configs: $e');
    }
  }

  void _startStatusUpdates() {
    _statusSubscription = AmneziaVpnService.statusStream.listen((status) {
      setState(() {
        _vpnStatus = status;
      });
    });
  }

  void _startStatsUpdates() {
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_vpnStatus.isConnected) {
        try {
          final stats = await AmneziaVpnService.getStats();
          if (stats != null && mounted) {
            setState(() {
              _vpnStatus = VpnStatusInfo(
                status: _vpnStatus.status,
                errorMessage: _vpnStatus.errorMessage,
                lastUpdated: DateTime.now(),
                connectedConfig: _vpnStatus.connectedConfig,
                bytesIn: stats['bytesIn'] as int?,
                bytesOut: stats['bytesOut'] as int?,
                connectionDuration: stats['connectionDuration'] != null 
                    ? Duration(milliseconds: stats['connectionDuration'] as int)
                    : null,
              );
            });
          }
        } catch (e) {
          print('Error getting stats: $e');
        }
      }
    });
  }

  Future<void> _connectToVpn(VpnConfig config) async {
    try {
      // Set as active config first
      await ConfigService.setActiveConfig(config.id);
      
      final success = await AmneziaVpnService.startVpn(config);
      if (success) {
        setState(() {
          _activeConfig = config;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('VPN подключен'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось подключиться к VPN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка подключения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnectVpn() async {
    try {
      final success = await AmneziaVpnService.stopVpn();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('VPN отключен'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось отключить VPN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отключения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigEditorScreen(),
      ),
    ).then((newConfig) {
      if (newConfig != null && newConfig is VpnConfig) {
        _saveNewConfig(newConfig);
      }
    });
  }

  Future<void> _saveNewConfig(VpnConfig config) async {
    try {
      final success = await ConfigService.addConfig(config);
      if (success) {
        await _loadConfigs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Конфигурация добавлена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editConfig(VpnConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigEditorScreen(config: config),
      ),
    ).then((editedConfig) {
      if (editedConfig != null && editedConfig is VpnConfig) {
        _updateConfig(editedConfig);
      }
    });
  }

  Future<void> _updateConfig(VpnConfig config) async {
    try {
      final success = await ConfigService.updateConfig(config);
      if (success) {
        await _loadConfigs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Конфигурация обновлена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteConfig(VpnConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Удалить конфигурацию',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы уверены, что хотите удалить конфигурацию "${config.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteConfig(config);
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteConfig(VpnConfig config) async {
    try {
      final success = await ConfigService.deleteConfig(config.id);
      if (success) {
        await _loadConfigs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Конфигурация удалена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Prosto.Net',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadConfigs,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF4ECDC4),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // VPN Status Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: VpnStatusCard(
              status: _vpnStatus,
              activeConfig: _activeConfig,
              onConnect: _activeConfig != null ? () => _connectToVpn(_activeConfig!) : null,
              onDisconnect: _disconnectVpn,
            ),
          ),
          
          // Configs List
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF16213E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Конфигурации',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _addNewConfig,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4ECDC4),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _configs.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.vpn_key_off,
                                  size: 64,
                                  color: Color(0xFF4ECDC4),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Нет конфигураций',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Добавьте первую конфигурацию',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _configs.length,
                            itemBuilder: (context, index) {
                              final config = _configs[index];
                              return ConfigListItem(
                                config: config,
                                isActive: _activeConfig?.id == config.id,
                                onTap: () => _connectToVpn(config),
                                onEdit: () => _editConfig(config),
                                onDelete: () => _deleteConfig(config),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

