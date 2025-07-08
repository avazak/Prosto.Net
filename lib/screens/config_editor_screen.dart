import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vpn_config.dart';
import '../services/config_service.dart';

class ConfigEditorScreen extends StatefulWidget {
  final VpnConfig? config;

  const ConfigEditorScreen({super.key, this.config});

  @override
  State<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends State<ConfigEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _configController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _nameController.text = widget.config!.name;
      _configController.text = widget.config!.configData;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _configController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final config = VpnConfig(
        id: widget.config?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        configData: _configController.text.trim(),
        createdAt: widget.config?.createdAt ?? DateTime.now(),
      );

      // TODO: Save to storage
      Navigator.pop(context, config);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final config = await ConfigService.loadFromFile();
      if (config != null) {
        setState(() {
          _configController.text = config;
          if (_nameController.text.isEmpty) {
            _nameController.text = ConfigService.extractConfigName(config);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadFromQr() async {
    try {
      final config = await ConfigService.loadFromQrCode(context);
      if (config != null) {
        setState(() {
          _configController.text = config;
          if (_nameController.text.isEmpty) {
            _nameController.text = ConfigService.extractConfigName(config);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сканирования QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadFromServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await ConfigService.loadFromServer();
      if (config != null) {
        setState(() {
          _configController.text = config;
          if (_nameController.text.isEmpty) {
            _nameController.text = ConfigService.extractConfigName(config);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки с сервера: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(
          widget.config != null ? 'Редактировать конфигурацию' : 'Новая конфигурация',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveConfig,
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    const Text(
                      'Название конфигурации',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Введите название',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF16213E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название конфигурации';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Import Options
                    const Text(
                      'Импорт конфигурации',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildImportButton(
                            icon: Icons.file_upload,
                            label: 'Файл',
                            onPressed: _loadFromFile,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildImportButton(
                            icon: Icons.qr_code_scanner,
                            label: 'QR код',
                            onPressed: _loadFromQr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildImportButton(
                            icon: Icons.cloud_download,
                            label: 'Сервер',
                            onPressed: _loadFromServer,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Config Data Field
                    const Text(
                      'Данные конфигурации',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _configController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      maxLines: 15,
                      decoration: InputDecoration(
                        hintText: '[Interface]\nPrivateKey = ...\n\n[Peer]\nPublicKey = ...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF16213E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите данные конфигурации';
                        }
                        if (!ConfigService.isValidConfig(value)) {
                          return 'Некорректный формат конфигурации';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: const Color(0xFF4ECDC4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

