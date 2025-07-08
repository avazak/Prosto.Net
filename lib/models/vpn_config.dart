class VpnConfig {
  final String id;
  final String name;
  final String configData;
  final DateTime createdAt;
  final bool isActive;

  VpnConfig({
    required this.id,
    required this.name,
    required this.configData,
    required this.createdAt,
    this.isActive = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'configData': configData,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory VpnConfig.fromJson(Map<String, dynamic> json) {
    return VpnConfig(
      id: json['id'],
      name: json['name'],
      configData: json['configData'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? false,
    );
  }

  VpnConfig copyWith({
    String? id,
    String? name,
    String? configData,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return VpnConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      configData: configData ?? this.configData,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

