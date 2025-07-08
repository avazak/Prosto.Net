import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/vpn_config.dart';
import '../screens/qr_scanner_screen.dart';

class ConfigService {
  static const String _configsFileName = 'vpn_configs.json';
  static const String _serverUrl = 'http://5.252.21.194:8090/api/get-config';

  // Load all configs from storage
  static Future<List<VpnConfig>> loadConfigs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_configsFileName');
      
      if (!await file.exists()) {
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) => VpnConfig.fromJson(json)).toList();
    } catch (e) {
      print('Error loading configs: $e');
      return [];
    }
  }

  // Save all configs to storage
  static Future<bool> saveConfigs(List<VpnConfig> configs) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_configsFileName');
      
      final jsonList = configs.map((config) => config.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      print('Error saving configs: $e');
      return false;
    }
  }

  // Add new config
  static Future<bool> addConfig(VpnConfig config) async {
    try {
      final configs = await loadConfigs();
      configs.add(config);
      return await saveConfigs(configs);
    } catch (e) {
      print('Error adding config: $e');
      return false;
    }
  }

  // Update existing config
  static Future<bool> updateConfig(VpnConfig updatedConfig) async {
    try {
      final configs = await loadConfigs();
      final index = configs.indexWhere((c) => c.id == updatedConfig.id);
      
      if (index != -1) {
        configs[index] = updatedConfig;
        return await saveConfigs(configs);
      }
      
      return false;
    } catch (e) {
      print('Error updating config: $e');
      return false;
    }
  }

  // Delete config
  static Future<bool> deleteConfig(String configId) async {
    try {
      final configs = await loadConfigs();
      configs.removeWhere((c) => c.id == configId);
      return await saveConfigs(configs);
    } catch (e) {
      print('Error deleting config: $e');
      return false;
    }
  }

  // Load config from file
  static Future<String?> loadFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['conf', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        return await file.readAsString();
      }
      
      return null;
    } catch (e) {
      throw Exception('Ошибка загрузки файла: $e');
    }
  }

  // Load config from QR code
  static Future<String?> loadFromQrCode(BuildContext context) async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QrScannerScreen(),
        ),
      );
      
      return result;
    } catch (e) {
      throw Exception('Ошибка сканирования QR кода: $e');
    }
  }

  // Load config from server
  static Future<String?> loadFromServer() async {
    try {
      final response = await http.get(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Assuming server returns config data directly
        return response.body;
      } else {
        throw Exception('Сервер вернул ошибку: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ошибка загрузки с сервера: $e');
    }
  }

  // Validate config format
  static bool isValidConfig(String configData) {
    try {
      // Basic validation for WireGuard config format
      final lines = configData.split('\n');
      bool hasInterface = false;
      bool hasPeer = false;
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('[Interface]')) {
          hasInterface = true;
        } else if (trimmed.startsWith('[Peer]')) {
          hasPeer = true;
        }
      }
      
      return hasInterface && hasPeer;
    } catch (e) {
      return false;
    }
  }

  // Extract config name from config data
  static String extractConfigName(String configData) {
    try {
      final lines = configData.split('\n');
      
      // Look for a comment with name
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('# Name:') || trimmed.startsWith('#Name:')) {
          return trimmed.substring(trimmed.indexOf(':') + 1).trim();
        }
      }
      
      // If no name found, generate one based on endpoint
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('Endpoint')) {
          final endpoint = trimmed.split('=')[1].trim();
          return 'Config ${endpoint.split(':')[0]}';
        }
      }
      
      return 'Новая конфигурация';
    } catch (e) {
      return 'Новая конфигурация';
    }
  }

  // Set active config
  static Future<bool> setActiveConfig(String configId) async {
    try {
      final configs = await loadConfigs();
      
      // Deactivate all configs
      for (int i = 0; i < configs.length; i++) {
        configs[i] = configs[i].copyWith(isActive: false);
      }
      
      // Activate selected config
      final index = configs.indexWhere((c) => c.id == configId);
      if (index != -1) {
        configs[index] = configs[index].copyWith(isActive: true);
        return await saveConfigs(configs);
      }
      
      return false;
    } catch (e) {
      print('Error setting active config: $e');
      return false;
    }
  }

  // Get active config
  static Future<VpnConfig?> getActiveConfig() async {
    try {
      final configs = await loadConfigs();
      return configs.firstWhere(
        (config) => config.isActive,
        orElse: () => configs.isNotEmpty ? configs.first : throw Exception('No configs'),
      );
    } catch (e) {
      return null;
    }
  }
}

