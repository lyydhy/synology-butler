class PackageVolume {
  final String path;
  final String displayName;
  final String description;
  final String fsType;
  final String? freeBytes;

  const PackageVolume({
    required this.path,
    required this.displayName,
    required this.description,
    required this.fsType,
    required this.freeBytes,
  });
}
