import '../../domain/entities/package_item.dart';
import '../../domain/entities/package_volume.dart';
import '../../domain/repositories/package_repository.dart';
import '../api/package_api.dart';

class PackageRepositoryImpl implements PackageRepository {
  const PackageRepositoryImpl(this._api);

  final PackageApi _api;

  @override
  Future<List<PackageItem>> fetchStorePackages({
    bool others = false,
  }) async {
    final items = await _api.fetchStorePackages(others: others);

    return items
        .map(
          (item) => PackageItem(
            id: item.id,
            name: item.name,
            displayName: item.displayName,
            description: item.description,
            version: item.version,
            installedVersion: item.installedVersion,
            isInstalled: item.isInstalled,
            canUpdate: item.canUpdate,
            isRunning: item.isRunning,
            isBeta: item.isBeta,
            thumbnailUrl: item.thumbnailUrl,
            screenshots: item.screenshots,
            distributor: item.distributor,
            distributorUrl: item.distributorUrl,
            maintainer: item.maintainer,
            maintainerUrl: item.maintainerUrl,
            status: item.status,
            installPath: item.installPath,
            dsmAppName: item.dsmAppName,
            changelog: item.changelog,
            downloadCount: item.downloadCount,
            isThirdParty: others,
          ),
        )
        .toList();
  }

  @override
  Future<List<PackageItem>> fetchInstalledPackages() async {
    final items = await _api.fetchInstalledPackages();

    return items
        .map(
          (item) => PackageItem(
            id: item.id,
            name: item.name,
            displayName: item.displayName,
            description: item.description,
            version: item.version,
            installedVersion: item.installedVersion,
            isInstalled: item.isInstalled,
            canUpdate: item.canUpdate,
            isRunning: item.isRunning,
            isBeta: item.isBeta,
            thumbnailUrl: item.thumbnailUrl,
            screenshots: item.screenshots,
            distributor: item.distributor,
            distributorUrl: item.distributorUrl,
            maintainer: item.maintainer,
            maintainerUrl: item.maintainerUrl,
            status: item.status,
            installPath: item.installPath,
            dsmAppName: item.dsmAppName,
            changelog: item.changelog,
            downloadCount: item.downloadCount,
          ),
        )
        .toList();
  }

  @override
  Future<List<PackageVolume>> fetchVolumes() async {
    final items = await _api.fetchVolumes();

    return items
        .map(
          (item) => PackageVolume(
            path: item.path,
            displayName: item.displayName,
            description: item.description,
            fsType: item.fsType,
            freeBytes: item.freeBytes,
          ),
        )
        .toList();
  }

  @override
  Future<PackageQueueCheckResult> checkInstallQueue({
    required String packageId,
    required String version,
    bool beta = false,
  }) async {
    final data = await _api.checkInstallQueue(
      packageId: packageId,
      version: version,
      beta: beta,
    );

    final paused = (data['paused_pkgs'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final cause = (data['cause_pausing_pkgs'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return PackageQueueCheckResult(
      pausedPackages: paused,
      causePausingPackages: cause,
    );
  }

  @override
  Future<String> installPackage({
    required String packageId,
    required String volumePath,
  }) async {
    final data = await _api.installPackage(
      packageId: packageId,
      volumePath: volumePath,
    );

    return data['taskid']?.toString() ?? '';
  }

  @override
  Future<PackageInstallStatus> getInstallStatus({
    required String taskId,
  }) async {
    final data = await _api.getInstallStatus(taskId: taskId);

    final progressRaw = data['progress'];
    final progress = progressRaw is num ? progressRaw.toDouble() : double.tryParse(progressRaw?.toString() ?? '');

    return PackageInstallStatus(
      finished: data['finished'] == true,
      progress: progress,
      status: data['status']?.toString(),
    );
  }

  @override
  Future<void> startPackage({
    required String packageId,
    String? dsmAppName,
  }) {
    return _api.startPackage(
      packageId: packageId,
      dsmAppName: dsmAppName,
    );
  }

  @override
  Future<void> stopPackage({
    required String packageId,
  }) {
    return _api.stopPackage(packageId: packageId);
  }

  @override
  Future<void> uninstallPackage({
    required String packageId,
  }) {
    return _api.uninstallPackage(packageId: packageId);
  }
}
