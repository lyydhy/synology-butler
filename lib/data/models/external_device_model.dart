class ExternalDeviceVolumeModel {
  final String name;
  final String fileSystem;
  final String mountPath;
  final String totalSizeText;
  final String usedSizeText;

  const ExternalDeviceVolumeModel({
    required this.name,
    required this.fileSystem,
    required this.mountPath,
    required this.totalSizeText,
    required this.usedSizeText,
  });
}

class ExternalDeviceModel {
  final String id;
  final String name;
  final String bus;
  final String vendor;
  final String model;
  final String status;
  final bool canEject;
  final List<ExternalDeviceVolumeModel> volumes;

  const ExternalDeviceModel({
    required this.id,
    required this.name,
    required this.bus,
    required this.vendor,
    required this.model,
    required this.status,
    required this.canEject,
    this.volumes = const [],
  });
}
