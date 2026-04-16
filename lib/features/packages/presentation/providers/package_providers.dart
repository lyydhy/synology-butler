import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/package_api.dart';
import '../../../../data/repositories/package_repository_impl.dart';
import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/package_volume.dart';
import '../../../../domain/repositories/package_repository.dart';
import '../state/package_install_state.dart';

final packageApiProvider = Provider<PackageApi>((ref) {
  return DsmPackageApi();
});

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepositoryImpl(ref.read(packageApiProvider));
});

/// 套件安装相关的共享状态。
final packageInstallStateProvider = StateProvider<PackageInstallState>((ref) {
  return const PackageInstallState();
});

enum PackageSource { store, thirdParty, installed }

/// 统一套件数据源 provider，按来源过滤
final packagesProvider = FutureProvider.family<List<PackageItem>, PackageSource>((ref, source) async {
  final repo = ref.read(packageRepositoryProvider);
  switch (source) {
    case PackageSource.store:
      return repo.fetchStorePackages();
    case PackageSource.thirdParty:
      return repo.fetchStorePackages(others: true);
    case PackageSource.installed:
      return repo.fetchInstalledPackages();
  }
});

/// 兼容性别名

final packageVolumesProvider = FutureProvider<List<PackageVolume>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchVolumes();
});

/// 判断指定套件是否已安装。
bool isPackageInstalled(List<PackageItem> installed, {String? dsmAppName, String? name, String? displayName}) {
  return installed.any((item) {
    final appName = item.dsmAppName?.trim().toLowerCase() ?? '';
    final n = item.name.trim().toLowerCase();
    final d = item.displayName.trim().toLowerCase();
    final targetAppName = dsmAppName?.trim().toLowerCase() ?? '';
    final targetName = name?.trim().toLowerCase() ?? '';
    final targetDisplayName = displayName?.trim().toLowerCase() ?? '';

    return (targetAppName.isNotEmpty && appName == targetAppName) ||
        (targetName.isNotEmpty && (n == targetName || d == targetName)) ||
        (targetDisplayName.isNotEmpty && (n == targetDisplayName || d == targetDisplayName));
  });
}

final mergedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final store = await ref.watch(packagesProvider(PackageSource.store).future);
  final thirdParty = await ref.watch(packagesProvider(PackageSource.thirdParty).future);
  final installed = await ref.watch(packagesProvider(PackageSource.installed).future);

  final installedMap = {for (final item in installed) item.id: item};

  PackageItem merge(PackageItem item) {
    final installedItem = installedMap[item.id];
    if (installedItem == null) return item;

    final canUpdate = _compareVersions(installedItem.version, item.version) < 0;
    return PackageItem(
      id: item.id,
      name: item.name,
      displayName: item.displayName,
      description: item.description.isNotEmpty ? item.description : installedItem.description,
      version: item.version,
      installedVersion: installedItem.version,
      isInstalled: true,
      canUpdate: canUpdate,
      isRunning: installedItem.isRunning,
      isBeta: item.isBeta || installedItem.isBeta,
      thumbnailUrl: item.thumbnailUrl ?? installedItem.thumbnailUrl,
      screenshots: item.screenshots,
      distributor: item.distributor ?? installedItem.distributor,
      distributorUrl: item.distributorUrl ?? installedItem.distributorUrl,
      maintainer: item.maintainer ?? installedItem.maintainer,
      maintainerUrl: item.maintainerUrl ?? installedItem.maintainerUrl,
      status: installedItem.status ?? item.status,
      installPath: installedItem.installPath,
      dsmAppName: installedItem.dsmAppName ?? item.dsmAppName,
      changelog: item.changelog,
      downloadCount: item.downloadCount,
      isThirdParty: item.isThirdParty,
    );
  }

  // 官方套件优先（同一 id 不会同时出现在两边）
  final merged = [...store.map(merge), ...thirdParty.map(merge)];
  final mergedIds = merged.map((e) => e.id).toSet();

  // 补充只安装在本地、不在商店的套件
  for (final item in installed) {
    if (!mergedIds.contains(item.id)) {
      merged.add(item);
    }
  }

  return merged;
});

/// 统一套件操作类，替代 start/stop/uninstall/prepareInstall/install 五个 provider
class PackageActions {
  final Ref _ref;

  PackageActions(this._ref);

  PackageRepository get _repo => _ref.read(packageRepositoryProvider);

  Future<void> start(PackageItem item) async {
    await _repo.startPackage(packageId: item.id, dsmAppName: item.dsmAppName);
    _ref.invalidate(packagesProvider(PackageSource.installed));
    _ref.invalidate(mergedPackagesProvider);
  }

  Future<void> stop(PackageItem item) async {
    await _repo.stopPackage(packageId: item.id);
    _ref.invalidate(packagesProvider(PackageSource.installed));
    _ref.invalidate(mergedPackagesProvider);
  }

  Future<void> uninstall(PackageItem item) async {
    await _repo.uninstallPackage(packageId: item.id);
    _ref.invalidate(packagesProvider(PackageSource.store));
    _ref.invalidate(packagesProvider(PackageSource.thirdParty));
    _ref.invalidate(packagesProvider(PackageSource.installed));
    _ref.invalidate(mergedPackagesProvider);
  }

  Future<PackageQueueCheckResult> prepareInstall(PackageItem item) async {
    final queue = await _repo.checkInstallQueue(
      packageId: item.id,
      version: item.version,
      beta: item.isBeta,
    );
    final currentState = _ref.read(packageInstallStateProvider);
    _ref.read(packageInstallStateProvider.notifier).state = currentState.copyWith(
      pendingQueueImpact: queue,
    );
    return queue;
  }

  Future<void> install(PackageItem item, String volumePath) async {
    _ref.read(packageInstallStateProvider.notifier).state =
        _ref.read(packageInstallStateProvider).copyWith(
              installingId: item.id,
              statusText: '准备安装...',
            );

    try {
      final taskId = await _repo.installPackage(
            packageId: item.id,
            volumePath: volumePath,
          );

      if (taskId.isEmpty) {
        throw Exception('安装任务未返回 taskId');
      }

      for (var i = 0; i < 90; i++) {
        final status = await _repo.getInstallStatus(taskId: taskId);

        final progressText = status.progress != null
            ? '${status.progress!.toStringAsFixed(1)}%'
            : (status.status ?? '安装中...');

        _ref.read(packageInstallStateProvider.notifier).state =
            _ref.read(packageInstallStateProvider).copyWith(statusText: progressText);

        if (status.finished) {
          _ref.read(packageInstallStateProvider.notifier).state =
              _ref.read(packageInstallStateProvider).copyWith(statusText: '安装完成');
          break;
        }

        await Future<void>.delayed(const Duration(seconds: 2));
      }

      _ref.invalidate(packagesProvider(PackageSource.store));
      _ref.invalidate(packagesProvider(PackageSource.thirdParty));
      _ref.invalidate(packagesProvider(PackageSource.installed));
      _ref.invalidate(mergedPackagesProvider);
      _ref.invalidate(packageVolumesProvider);
      _ref.read(packageInstallStateProvider.notifier).state =
          _ref.read(packageInstallStateProvider).copyWith(clearPendingQueueImpact: true);
    } finally {
      _ref.read(packageInstallStateProvider.notifier).state =
          _ref.read(packageInstallStateProvider).copyWith(clearInstallingId: true);
    }
  }
}

final packageActionsProvider = Provider<PackageActions>((ref) {
  return PackageActions(ref);
});

int _compareVersions(String a, String b) {
  final aParts = a.split(RegExp(r'[^0-9]+')).where((e) => e.isNotEmpty).map(int.parse).toList();
  final bParts = b.split(RegExp(r'[^0-9]+')).where((e) => e.isNotEmpty).map(int.parse).toList();
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;

  for (var i = 0; i < length; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}
