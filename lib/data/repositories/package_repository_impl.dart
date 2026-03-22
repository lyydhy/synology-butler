import '../../core/utils/server_url_helper.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/entities/package_item.dart';
import '../../domain/entities/package_volume.dart';
import '../../domain/repositories/package_repository.dart';
import '../api/package_api.dart';

class PackageRepositoryImpl implements PackageRepository {
  const PackageRepositoryImpl(this._api);

  final PackageApi _api;

  @override
  Future<List<PackageItem>> fetchStorePackages({
    required NasServer server,
    required NasSession session,
    bool others = false,
  }) async {
    final items = await _api.fetchStorePackages(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
      others: others,
    );

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
          ),
        )
        .toList();
  }

  @override
  Future<List<PackageItem>> fetchInstalledPackages({
    required NasServer server,
    required NasSession session,
  }) async {
    final items = await _api.fetchInstalledPackages(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );

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
          ),
        )
        .toList();
  }

  @override
  Future<List<PackageVolume>> fetchVolumes({
    required NasServer server,
    required NasSession session,
  }) async {
    final items = await _api.fetchVolumes(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );

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
    required NasServer server,
    required NasSession session,
    required String packageId,
    required String version,
    bool beta = false,
  }) async {
    final data = await _api.checkInstallQueue(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      packageId: packageId,
      version: version,
      beta: beta,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
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
    required NasServer server,
    required NasSession session,
    required String packageId,
    required String volumePath,
  }) async {
    final data = await _api.installPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      packageId: packageId,
      volumePath: volumePath,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );

    return data['taskid']?.toString() ?? '';
  }

  @override
  Future<PackageInstallStatus> getInstallStatus({
    required NasServer server,
    required NasSession session,
    required String taskId,
  }) async {
    final data = await _api.getInstallStatus(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      taskId: taskId,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );

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
    required NasServer server,
    required NasSession session,
    required String packageId,
    String? dsmAppName,
  }) {
    return _api.startPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      packageId: packageId,
      dsmAppName: dsmAppName,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<void> stopPackage({
    required NasServer server,
    required NasSession session,
    required String packageId,
  }) {
    return _api.stopPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      packageId: packageId,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<void> uninstallPackage({
    required NasServer server,
    required NasSession session,
    required String packageId,
  }) {
    return _api.uninstallPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      packageId: packageId,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }
}
