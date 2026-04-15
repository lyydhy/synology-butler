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

final storePackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchStorePackages();
});

/// 社群/第三方套件
final thirdPartyPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchStorePackages(others: true);
});

final installedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchInstalledPackages();
});

final packageVolumesProvider = FutureProvider<List<PackageVolume>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchVolumes();
});

/// 判断当前 NAS 是否已安装 Docker / Container Manager。
 ///
 /// 这里复用套件列表数据做能力判断，避免额外新增一套探测链路。
 /// dsm_helper 里也是基于 DSM 应用标识来识别 Docker 入口：
 /// - `SYNO.SDS.Docker.Application`
 /// - `SYNO.SDS.ContainerManager.Application`
final dockerFeatureInstalledProvider = FutureProvider<bool>((ref) async {
  final installed = await ref.watch(installedPackagesProvider.future);

  bool matches(PackageItem item) {
    final appName = item.dsmAppName?.trim() ?? '';
    final name = item.name.trim().toLowerCase();
    final displayName = item.displayName.trim().toLowerCase();

    return appName == 'SYNO.SDS.Docker.Application' ||
        appName == 'SYNO.SDS.ContainerManager.Application' ||
        name == 'docker' ||
        name == 'container manager' ||
        displayName == 'docker' ||
        displayName == 'container manager';
  }

  return installed.any(matches);
});

/// 判断当前 NAS 是否已安装 Download Station。
final downloadStationFeatureInstalledProvider = FutureProvider<bool>((ref) async {
  final installed = await ref.watch(installedPackagesProvider.future);

  bool matches(PackageItem item) {
    final appName = item.dsmAppName?.trim() ?? '';
    final name = item.name.trim().toLowerCase();
    final displayName = item.displayName.trim().toLowerCase();

    return appName == 'SYNO.SDS.DownloadStation.Application' ||
        name == 'download station' ||
        displayName == 'download station';
  }

  return installed.any(matches);
});

final mergedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final store = await ref.watch(storePackagesProvider.future);
  final thirdParty = await ref.watch(thirdPartyPackagesProvider.future);
  final installed = await ref.watch(installedPackagesProvider.future);

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

final packageStartProvider = Provider<Future<void> Function(PackageItem)>((ref) {
  return (item) async {
    await ref.read(packageRepositoryProvider).startPackage(packageId: item.id, dsmAppName: item.dsmAppName);
    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
  };
});

final packageStopProvider = Provider<Future<void> Function(PackageItem)>((ref) {
  return (item) async {
    await ref.read(packageRepositoryProvider).stopPackage(packageId: item.id);
    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
  };
});

final packageUninstallProvider = Provider<Future<void> Function(PackageItem)>((ref) {
  return (item) async {
    await ref.read(packageRepositoryProvider).uninstallPackage(packageId: item.id);
    ref.invalidate(storePackagesProvider);
    ref.invalidate(thirdPartyPackagesProvider);
    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
  };
});

final packagePrepareInstallProvider = Provider<Future<PackageQueueCheckResult> Function(PackageItem)>((ref) {
  return (item) async {
    final queue = await ref.read(packageRepositoryProvider).checkInstallQueue(
          packageId: item.id,
          version: item.version,
          beta: item.isBeta,
        );

    final currentState = ref.read(packageInstallStateProvider);
    ref.read(packageInstallStateProvider.notifier).state = currentState.copyWith(
      pendingQueueImpact: queue,
    );
    return queue;
  };
});

final packageInstallProvider = Provider<Future<void> Function(PackageItem, String)>((ref) {
  return (item, volumePath) async {
    ref.read(packageInstallStateProvider.notifier).state =
        ref.read(packageInstallStateProvider).copyWith(
              installingId: item.id,
              statusText: '准备安装...',
            );

    try {
      final taskId = await ref.read(packageRepositoryProvider).installPackage(
            packageId: item.id,
            volumePath: volumePath,
          );

      if (taskId.isEmpty) {
        throw Exception('安装任务未返回 taskId');
      }

      for (var i = 0; i < 90; i++) {
        final status = await ref.read(packageRepositoryProvider).getInstallStatus(taskId: taskId);

        final progressText = status.progress != null
            ? '${status.progress!.toStringAsFixed(1)}%'
            : (status.status ?? '安装中...');

        ref.read(packageInstallStateProvider.notifier).state =
            ref.read(packageInstallStateProvider).copyWith(statusText: progressText);

        if (status.finished) {
          ref.read(packageInstallStateProvider.notifier).state =
              ref.read(packageInstallStateProvider).copyWith(statusText: '安装完成');
          break;
        }

        await Future<void>.delayed(const Duration(seconds: 2));
      }

      ref.invalidate(storePackagesProvider);
    ref.invalidate(thirdPartyPackagesProvider);
      ref.invalidate(installedPackagesProvider);
      ref.invalidate(mergedPackagesProvider);
      ref.invalidate(packageVolumesProvider);
      ref.read(packageInstallStateProvider.notifier).state =
          ref.read(packageInstallStateProvider).copyWith(clearPendingQueueImpact: true);
    } finally {
      ref.read(packageInstallStateProvider.notifier).state =
          ref.read(packageInstallStateProvider).copyWith(clearInstallingId: true);
    }
  };
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
