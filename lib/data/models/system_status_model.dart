class StorageVolumeStatusModel {
  final String name;
  final double usage;

  const StorageVolumeStatusModel({
    required this.name,
    required this.usage,
  });
}

class SystemStatusModel {
  final String serverName;
  final String dsmVersion;
  final double cpuUsage;
  final double memoryUsage;
  final double storageUsage;
  final List<StorageVolumeStatusModel> volumes;
  final String? modelName;
  final String? serialNumber;
  final String? uptimeText;

  const SystemStatusModel({
    required this.serverName,
    required this.dsmVersion,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.storageUsage,
    this.volumes = const [],
    this.modelName,
    this.serialNumber,
    this.uptimeText,
  });
}
