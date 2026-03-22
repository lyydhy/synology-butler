class PackageItemModel {
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

  const PackageItemModel({
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
  });

  factory PackageItemModel.fromStorePayload(Map map) {
    final thumbnails = (map['thumbnail'] as List?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ?? const <String>[];
    final snapshots = (map['snapshot'] as List?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ?? const <String>[];

    return PackageItemModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['id'] ?? '').toString(),
      displayName: (map['dname'] ?? map['name'] ?? map['id'] ?? '').toString(),
      description: (map['desc'] ?? map['description'] ?? map['description_enu'] ?? '').toString(),
      version: (map['version'] ?? '').toString(),
      installedVersion: map['installed_version']?.toString(),
      isInstalled: map['installed'] == true,
      canUpdate: map['can_update'] == true,
      isRunning: map['launched'] == true || (map['additional'] is Map && map['additional']['status'] == 'running'),
      isBeta: map['beta'] == true,
      thumbnailUrl: thumbnails.isEmpty ? null : thumbnails.last,
      screenshots: snapshots,
      distributor: map['distributor']?.toString(),
      distributorUrl: map['distributor_url']?.toString(),
      maintainer: map['maintainer']?.toString(),
      maintainerUrl: map['maintainer_url']?.toString(),
      status: map['additional'] is Map ? map['additional']['status']?.toString() : map['status']?.toString(),
      installPath: map['additional'] is Map && map['additional']['installed_info'] is Map
          ? map['additional']['installed_info']['path']?.toString()
          : null,
      dsmAppName: map['dsm_apps'] is List && (map['dsm_apps'] as List).isNotEmpty ? map['dsm_apps'].first.toString() : null,
    );
  }

  factory PackageItemModel.fromInstalledPayload(Map map) {
    final additional = map['additional'] as Map? ?? const {};
    final dsmApps = additional['dsm_apps'] as List? ?? map['dsm_apps'] as List? ?? const [];
    final installedInfo = additional['installed_info'] as Map? ?? const {};

    return PackageItemModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['id'] ?? '').toString(),
      displayName: (map['dname'] ?? map['name'] ?? map['id'] ?? '').toString(),
      description: (additional['description'] ?? additional['description_enu'] ?? map['description'] ?? '').toString(),
      version: (map['version'] ?? '').toString(),
      installedVersion: (map['version'] ?? '').toString(),
      isInstalled: true,
      canUpdate: false,
      isRunning: additional['status']?.toString() == 'running' || map['status']?.toString() == 'running',
      isBeta: additional['beta'] == true || map['beta'] == true,
      thumbnailUrl: map['thumbnail']?.toString(),
      screenshots: const [],
      distributor: additional['distributor']?.toString(),
      distributorUrl: additional['distributor_url']?.toString(),
      maintainer: additional['maintainer']?.toString(),
      maintainerUrl: additional['maintainer_url']?.toString(),
      status: additional['status']?.toString() ?? map['status']?.toString(),
      installPath: installedInfo['path']?.toString(),
      dsmAppName: dsmApps.isNotEmpty ? dsmApps.first.toString() : null,
    );
  }
}
