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

final installedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchInstalledPackages();
});

final packageVolumesProvider = FutureProvider<List<PackageVolume>>((ref) async {
  return ref.read(packageRepositoryProvider).fetchVolumes();
});

final mergedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final store = await ref.watch(storePackagesProvider.future);
  final installed = await ref.watch(installedPackagesProvider.future);

  final installedMap = {for (final item in installed) item.id: item};

  final merged = store.map((item) {
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
    );
  }).toList();

  final existingIds = merged.map((e) => e.id).toSet();
  for (final item in installed) {
    if (!existingIds.contains(item.id)) {
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
