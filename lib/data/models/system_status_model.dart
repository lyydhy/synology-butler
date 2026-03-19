class SystemStatusModel {
  final String serverName;
  final String dsmVersion;
  final double cpuUsage;
  final double memoryUsage;
  final double storageUsage;
  final String? modelName;
  final String? serialNumber;
  final String? uptimeText;

  const SystemStatusModel({
    required this.serverName,
    required this.dsmVersion,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.storageUsage,
    this.modelName,
    this.serialNumber,
    this.uptimeText,
  });
}
