import 'dart:convert';

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

  /// 兼容 DSM 套件接口里 `dsm_apps` 的多种返回形式：
  /// - 直接 List<String>
  /// - List<Map>，其中带有 className / app 等字段
  /// - JSON 字符串
  /// - 单个字符串
  static String? _extractDsmAppName(dynamic raw) {
    List<dynamic> values = const [];

    if (raw is List) {
      values = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      final trimmed = raw.trim();
      if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
          (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            values = decoded;
          } else {
            values = [decoded];
          }
        } catch (_) {
          values = [trimmed];
        }
      } else {
        values = [trimmed];
      }
    } else if (raw is Map) {
      values = [raw];
    }

    for (final item in values) {
      if (item is String && item.trim().isNotEmpty) {
        return item.trim();
      }
      if (item is Map) {
        final candidate = (item['className'] ?? item['class_name'] ?? item['app'] ?? item['name'])?.toString();
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    return null;
  }

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
      dsmAppName: _extractDsmAppName(map['dsm_apps']),
    );
  }

  factory PackageItemModel.fromInstalledPayload(Map map) {
    final additional = map['additional'] as Map? ?? const {};
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
      dsmAppName: _extractDsmAppName(additional['dsm_apps'] ?? map['dsm_apps']),
    );
  }
}
