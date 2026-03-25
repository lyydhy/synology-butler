class StorageVolumeStatus {
  final String name;
  final double usage;
  final double? usedBytes;
  final double? totalBytes;

  const StorageVolumeStatus({
    required this.name,
    required this.usage,
    this.usedBytes,
    this.totalBytes,
  });
}

class VolumePerformanceStatus {
  final String name;
  final double utilization;
  final double readBytesPerSecond;
  final double writeBytesPerSecond;
  final double readIops;
  final double writeIops;

  const VolumePerformanceStatus({
    required this.name,
    required this.utilization,
    required this.readBytesPerSecond,
    required this.writeBytesPerSecond,
    required this.readIops,
    required this.writeIops,
  });
}

class NetworkInterfaceStatus {
  final String name;
  final double uploadBytesPerSecond;
  final double downloadBytesPerSecond;

  const NetworkInterfaceStatus({
    required this.name,
    required this.uploadBytesPerSecond,
    required this.downloadBytesPerSecond,
  });
}

class DiskStatus {
  final String name;
  final double utilization;
  final double readBytesPerSecond;
  final double writeBytesPerSecond;
  final double readIops;
  final double writeIops;

  const DiskStatus({
    required this.name,
    required this.utilization,
    required this.readBytesPerSecond,
    required this.writeBytesPerSecond,
    required this.readIops,
    required this.writeIops,
  });
}

class SystemStatus {
  final String serverName;
  final String dsmVersion;
  final double cpuUsage;
  final double cpuUserUsage;
  final double cpuSystemUsage;
  final double cpuIoWaitUsage;
  final double load1;
  final double load5;
  final double load15;
  final double memoryUsage;
  final double memoryTotalBytes;
  final double memoryUsedBytes;
  final double memoryBufferBytes;
  final double memoryCachedBytes;
  final double memoryAvailableBytes;
  final double storageUsage;
  final double networkUploadBytesPerSecond;
  final double networkDownloadBytesPerSecond;
  final double diskReadBytesPerSecond;
  final double diskWriteBytesPerSecond;
  final List<NetworkInterfaceStatus> networkInterfaces;
  final List<DiskStatus> disks;
  final List<VolumePerformanceStatus> volumePerformances;
  final List<StorageVolumeStatus> volumes;
  final String? modelName;
  final String? serialNumber;
  final String? uptimeText;

  const SystemStatus({
    required this.serverName,
    required this.dsmVersion,
    required this.cpuUsage,
    this.cpuUserUsage = 0,
    this.cpuSystemUsage = 0,
    this.cpuIoWaitUsage = 0,
    this.load1 = 0,
    this.load5 = 0,
    this.load15 = 0,
    required this.memoryUsage,
    this.memoryTotalBytes = 0,
    this.memoryUsedBytes = 0,
    this.memoryBufferBytes = 0,
    this.memoryCachedBytes = 0,
    this.memoryAvailableBytes = 0,
    required this.storageUsage,
    this.networkUploadBytesPerSecond = 0,
    this.networkDownloadBytesPerSecond = 0,
    this.diskReadBytesPerSecond = 0,
    this.diskWriteBytesPerSecond = 0,
    this.networkInterfaces = const [],
    this.disks = const [],
    this.volumePerformances = const [],
    this.volumes = const [],
    this.modelName,
    this.serialNumber,
    this.uptimeText,
  });
}
