class InformationCenterLanNetwork {
  final String name;
  final String? macAddress;
  final String? ipAddress;
  final String? subnetMask;

  const InformationCenterLanNetwork({
    required this.name,
    this.macAddress,
    this.ipAddress,
    this.subnetMask,
  });
}

class InformationCenterExternalDevice {
  final String name;
  final String? type;
  final String? status;

  const InformationCenterExternalDevice({
    required this.name,
    this.type,
    this.status,
  });
}

class InformationCenterDisk {
  final String name;
  final String? serialNumber;
  final double? capacityBytes;
  final String? temperatureText;

  const InformationCenterDisk({
    required this.name,
    this.serialNumber,
    this.capacityBytes,
    this.temperatureText,
  });
}

class InformationCenterData {
  final String serverName;
  final String? serialNumber;
  final String? modelName;
  final String? cpuName;
  final int? cpuCores;
  final double? memoryBytes;
  final String? dsmVersion;
  final String? systemTime;
  final String? uptimeText;
  final String? thermalStatus;
  final String? timezone;
  final String? dnsServer;
  final String? gateway;
  final String? workgroup;
  final List<InformationCenterExternalDevice> externalDevices;
  final List<InformationCenterLanNetwork> lanNetworks;
  final List<InformationCenterDisk> disks;

  const InformationCenterData({
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
  });
}
