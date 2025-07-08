import 'package:flutter/material.dart';
import '../models/vpn_config.dart';
import '../models/vpn_status.dart';

class VpnStatusCard extends StatelessWidget {
  final VpnStatusInfo status;
  final VpnConfig? activeConfig;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const VpnStatusCard({
    super.key,
    required this.status,
    this.activeConfig,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon and Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (activeConfig != null)
                    Text(
                      activeConfig!.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Connection Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _getButtonCallback(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _getStatusColor(),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Error Message
          if (status.hasError && status.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Connection Stats
          if (status.isConnected && status.bytesIn != null && status.bytesOut != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Загружено', _formatBytes(status.bytesIn!)),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatItem('Отправлено', _formatBytes(status.bytesOut!)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.status) {
      case VpnStatus.connected:
        return const Color(0xFF4ECDC4);
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return const Color(0xFFF39C12);
      case VpnStatus.error:
        return const Color(0xFFE74C3C);
      case VpnStatus.disconnected:
        return const Color(0xFF95A5A6);
    }
  }

  List<Color> _getGradientColors() {
    final baseColor = _getStatusColor();
    return [
      baseColor,
      baseColor.withOpacity(0.8),
    ];
  }

  IconData _getStatusIcon() {
    switch (status.status) {
      case VpnStatus.connected:
        return Icons.shield;
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return Icons.sync;
      case VpnStatus.error:
        return Icons.error;
      case VpnStatus.disconnected:
        return Icons.shield_outlined;
    }
  }

  String _getButtonText() {
    switch (status.status) {
      case VpnStatus.connected:
        return 'Отключиться';
      case VpnStatus.connecting:
        return 'Подключение...';
      case VpnStatus.disconnecting:
        return 'Отключение...';
      case VpnStatus.error:
      case VpnStatus.disconnected:
        return 'Подключиться';
    }
  }

  VoidCallback? _getButtonCallback() {
    switch (status.status) {
      case VpnStatus.connected:
        return onDisconnect;
      case VpnStatus.connecting:
      case VpnStatus.disconnecting:
        return null;
      case VpnStatus.error:
      case VpnStatus.disconnected:
        return onConnect;
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

