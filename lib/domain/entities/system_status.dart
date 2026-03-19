class StorageVolumeStatus {
  final String name;
  final double usage;

  const StorageVolumeStatus({
    required this.name,
    required this.usage,
  });
}

class SystemStatus {
  final String serverName;
  final String dsmVersion;
  final double cpuUsage;
  final double memoryUsage;
  final double storageUsage;
  final List<StorageVolumeStatus> volumes;
  final String? modelName;
  final String? serialNumber;
  final String? uptimeText;

  const SystemStatus({
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
