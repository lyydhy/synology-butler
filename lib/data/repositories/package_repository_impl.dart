import '../../core/network/business_connection_context.dart';
import '../../core/utils/server_url_helper.dart';
import '../../domain/entities/package_item.dart';
import '../../domain/entities/package_volume.dart';
import '../../domain/repositories/package_repository.dart';
import '../api/package_api.dart';

class PackageRepositoryImpl implements PackageRepository {
  const PackageRepositoryImpl(this._api, this._context);

  final PackageApi _api;
  final BusinessConnectionContext _context;

  @override
  Future<List<PackageItem>> fetchStorePackages({
    bool others = false,
  }) async {
    final items = await _api.fetchStorePackages(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
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
  Future<List<PackageItem>> fetchInstalledPackages() async {
    final items = await _api.fetchInstalledPackages(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
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
  Future<List<PackageVolume>> fetchVolumes() async {
    final items = await _api.fetchVolumes(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
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
    required String packageId,
    required String version,
    bool beta = false,
  }) async {
    final data = await _api.checkInstallQueue(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      packageId: packageId,
      version: version,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
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
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      packageId: packageId,
      volumePath: volumePath,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );

    return data['taskid']?.toString() ?? '';
  }

  @override
  Future<PackageInstallStatus> getInstallStatus({
    required String taskId,
  }) async {
    final data = await _api.getInstallStatus(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      taskId: taskId,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
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
    required String packageId,
    String? dsmAppName,
  }) {
    return _api.startPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      packageId: packageId,
      dsmAppName: dsmAppName,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<void> stopPackage({
    required String packageId,
  }) {
    return _api.stopPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      packageId: packageId,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<void> uninstallPackage({
    required String packageId,
  }) {
    return _api.uninstallPackage(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      packageId: packageId,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }
}
