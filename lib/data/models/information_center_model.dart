class InformationCenterLanNetworkModel {
  final String name;
  final String? macAddress;
  final String? ipAddress;
  final String? subnetMask;

  const InformationCenterLanNetworkModel({
    required this.name,
    this.macAddress,
    this.ipAddress,
    this.subnetMask,
  });
}

class InformationCenterExternalDeviceModel {
  final String name;
  final String? type;
  final String? status;

  const InformationCenterExternalDeviceModel({
    required this.name,
    this.type,
    this.status,
  });
}

class InformationCenterDiskModel {
  final String name;
  final String? serialNumber;
  final double? capacityBytes;
  final String? temperatureText;

  const InformationCenterDiskModel({
    required this.name,
    this.serialNumber,
    this.capacityBytes,
    this.temperatureText,
  });
}

class InformationCenterModel {
  final String serverName;
  final String? serialNumber;
  final String? modelName;
  final String? cpuName;
  final int? cpuCores;
  final String? cpuClockSpeedStr;
  final int? ramSize;
  final double? memoryBytes;
  final String? dsmVersion;
  final String? systemTime;
  final String? uptimeText;
  final String? thermalStatus;
  final String? timezone;
  final String? dnsServer;
  final String? gateway;
  final String? workgroup;
  final List<InformationCenterExternalDeviceModel> externalDevices;
  final List<InformationCenterLanNetworkModel> lanNetworks;
  final List<InformationCenterDiskModel> disks;
  final String? time;
  final int? sysTemp;
  final bool? temperatureWarning;

  const InformationCenterModel({
    required this.serverName,
    this.serialNumber,
    this.modelName,
    this.cpuName,
    this.cpuCores,
    this.memoryBytes,
    this.dsmVersion,
    this.systemTime,
    this.uptimeText,
    this.thermalStatus,
    this.timezone,
    this.dnsServer,
    this.gateway,
    this.workgroup,
    this.externalDevices = const [],
    this.lanNetworks = const [],
    this.disks = const [],
    this.ramSize,
    this.cpuClockSpeedStr,
    this.time,
    this.sysTemp,
    this.temperatureWarning,
  });
}
