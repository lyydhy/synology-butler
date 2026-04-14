class PackageItem {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String version;
  final String? installedVersion;
  final bool isInstalled;
  final bool canUpdate;
  final bool isRunning;
  final bool isBeta;
  final String? thumbnailUrl;
  final List<String> screenshots;
  final String? distributor;
  final String? distributorUrl;
  final String? maintainer;
  final String? maintainerUrl;
  final String? status;
  final String? installPath;
  final String? dsmAppName;
  final String? changelog;
  final int? downloadCount;
  final bool isThirdParty;

  const PackageItem({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.version,
    required this.installedVersion,
    required this.isInstalled,
    required this.canUpdate,
    required this.isRunning,
    required this.isBeta,
    required this.thumbnailUrl,
    required this.screenshots,
    required this.distributor,
    required this.distributorUrl,
    required this.maintainer,
    required this.maintainerUrl,
    required this.status,
    required this.installPath,
    required this.dsmAppName,
    this.changelog,
    this.downloadCount,
    this.isThirdParty = false,
  });
}
