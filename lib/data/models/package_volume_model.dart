class PackageVolumeModel {
  final String path;
  final String displayName;
  final String description;
  final String fsType;
  final String? freeBytes;

  const PackageVolumeModel({
    required this.path,
    required this.displayName,
    required this.description,
    required this.fsType,
    required this.freeBytes,
  });

  factory PackageVolumeModel.fromMap(Map map) {
    return PackageVolumeModel(
      path: (map['volume_path'] ?? map['path'] ?? '').toString(),
      displayName: (map['display_name'] ?? map['name'] ?? map['volume_path'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      fsType: (map['fs_type'] ?? '').toString(),
      freeBytes: map['size_free_byte']?.toString(),
    );
  }
}
