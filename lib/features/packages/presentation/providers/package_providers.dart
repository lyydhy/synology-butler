import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/package_api.dart';
import '../../../../data/repositories/package_repository_impl.dart';
import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/package_volume.dart';
import '../../../../domain/repositories/package_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final packageApiProvider = Provider<PackageApi>((ref) => DsmPackageApi());

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepositoryImpl(ref.read(packageApiProvider));
});

final packageTabProvider = StateProvider<String>((ref) => 'all');
final packageInstallingProvider = StateProvider<String?>((ref) => null);
final packageInstallStatusProvider = StateProvider<String?>((ref) => null);
final packagePendingQueueImpactProvider = StateProvider<PackageQueueCheckResult?>((ref) => null);

final storePackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);
  if (server == null || session == null) throw Exception('No active NAS session');

  return ref.read(packageRepositoryProvider).fetchStorePackages(
        server: server,
        session: session,
      );
});

final installedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);
  if (server == null || session == null) throw Exception('No active NAS session');

  return ref.read(packageRepositoryProvider).fetchInstalledPackages(
        server: server,
        session: session,
      );
});

final packageVolumesProvider = FutureProvider<List<PackageVolume>>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);
  if (server == null || session == null) throw Exception('No active NAS session');

  return ref.read(packageRepositoryProvider).fetchVolumes(
        server: server,
        session: session,
      );
});

final mergedPackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final store = await ref.watch(storePackagesProvider.future);
  final installed = await ref.watch(installedPackagesProvider.future);

  final installedMap = {
    for (final item in installed) item.id: item,
  };

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

final visiblePackagesProvider = FutureProvider<List<PackageItem>>((ref) async {
  final tab = ref.watch(packageTabProvider);
  final items = await ref.watch(mergedPackagesProvider.future);

  switch (tab) {
    case 'installed':
      return items.where((item) => item.isInstalled).toList();
    case 'updates':
      return items.where((item) => item.canUpdate).toList();
    default:
      return items;
  }
});

final packageStartProvider = Provider<Future<void> Function(PackageItem)>((ref) {
  return (item) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(packageRepositoryProvider).startPackage(
          server: server,
          session: session,
          packageId: item.id,
          dsmAppName: item.dsmAppName,
        );

    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
    ref.invalidate(visiblePackagesProvider);
  };
});

final packageStopProvider = Provider<Future<void> Function(PackageItem)>((ref) {
  return (item) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(packageRepositoryProvider).stopPackage(
          server: server,
          session: session,
          packageId: item.id,
        );

    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
    ref.invalidate(visiblePackagesProvider);
  };
});

final packageUninstallProvider = Provider<Future<void> Function(PackageItem)>((ref) {
  return (item) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(packageRepositoryProvider).uninstallPackage(
          server: server,
          session: session,
          packageId: item.id,
        );

    ref.invalidate(storePackagesProvider);
    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
    ref.invalidate(visiblePackagesProvider);
  };
});

final packagePrepareInstallProvider = Provider<Future<PackageQueueCheckResult> Function(PackageItem)>((ref) {
  return (item) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    final queue = await ref.read(packageRepositoryProvider).checkInstallQueue(
          server: server,
          session: session,
          packageId: item.id,
          version: item.version,
          beta: item.isBeta,
        );

    ref.read(packagePendingQueueImpactProvider.notifier).state = queue;
    return queue;
  };
});

final packageInstallProvider = Provider<Future<void> Function(PackageItem, String)>((ref) {
  return (item, volumePath) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    ref.read(packageInstallingProvider.notifier).state = item.id;
    ref.read(packageInstallStatusProvider.notifier).state = '准备安装…';

    try {
      final taskId = await ref.read(packageRepositoryProvider).installPackage(
            server: server,
            session: session,
            packageId: item.id,
            volumePath: volumePath,
          );

      if (taskId.isEmpty) {
        throw Exception('安装任务未返回 taskId');
      }

      for (var i = 0; i < 90; i++) {
        final status = await ref.read(packageRepositoryProvider).getInstallStatus(
              server: server,
              session: session,
              taskId: taskId,
            );

        final progressText = status.progress != null
            ? '${status.progress!.toStringAsFixed(1)}%'
            : (status.status ?? '安装中…');
        ref.read(packageInstallStatusProvider.notifier).state = progressText;

        if (status.finished) {
          ref.read(packageInstallStatusProvider.notifier).state = '安装完成';
          break;
        }

        await Future<void>.delayed(const Duration(seconds: 2));
      }

      ref.invalidate(storePackagesProvider);
      ref.invalidate(installedPackagesProvider);
      ref.invalidate(mergedPackagesProvider);
      ref.invalidate(visiblePackagesProvider);
      ref.invalidate(packageVolumesProvider);
      ref.read(packagePendingQueueImpactProvider.notifier).state = null;
    } finally {
      ref.read(packageInstallingProvider.notifier).state = null;
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
