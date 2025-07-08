enum VpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnStatusInfo {
  final VpnStatus status;
  final String? errorMessage;
  final DateTime lastUpdated;
  final String? connectedConfig;
  final int? bytesIn;
  final int? bytesOut;
  final Duration? connectionDuration;

  VpnStatusInfo({
    required this.status,
    this.errorMessage,
    required this.lastUpdated,
    this.connectedConfig,
    this.bytesIn,
    this.bytesOut,
    this.connectionDuration,
  });

  String get statusText {
    switch (status) {
      case VpnStatus.disconnected:
        return 'Отключено';
      case VpnStatus.connecting:
        return 'Подключение...';
      case VpnStatus.connected:
        return 'Подключено';
      case VpnStatus.disconnecting:
        return 'Отключение...';
      case VpnStatus.error:
        return 'Ошибка';
    }
  }

  bool get isConnected => status == VpnStatus.connected;
  bool get isConnecting => status == VpnStatus.connecting;
  bool get isDisconnecting => status == VpnStatus.disconnecting;
  bool get hasError => status == VpnStatus.error;
}

