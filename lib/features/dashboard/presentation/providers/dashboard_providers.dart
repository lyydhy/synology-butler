import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../data/api/system_api.dart';
import '../../../../data/repositories/system_repository_impl.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../domain/repositories/system_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'dashboard_realtime_global.dart';
import 'global_home_provider.dart';

final systemApiProvider = Provider<SystemApi>((ref) {
  final server = connectionStore.server;
  return DsmSystemApi(ignoreBadCertificate: server?.ignoreBadCertificate ?? false);
});

final systemRepositoryProvider = Provider<SystemRepository>((ref) {
  return SystemRepositoryImpl(ref.read(systemApiProvider));
});

bool _isSessionExpiredError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('session expired') ||
      text.contains('login required') ||
      text.contains('unauthorized') ||
      text.contains('invalid sid') ||
      text.contains('expired') ||
      text.contains('119');
}

Future<void> _handleSessionExpired(Ref ref) async {
  await ref.read(recoverSessionProvider)();
}

final dashboardOverviewSafeProvider = Provider<AsyncValue<SystemStatus?>>((ref) {
  final realtimeOverview = ref.watch(globalRealtimeOverviewProvider);
  final homeData = ref.watch(globalHomeProvider).valueOrNull;

  if (homeData == null) {
    if (ref.watch(globalHomeProvider).isLoading) {
      return const AsyncValue.loading();
    }
    return const AsyncValue.data(null);
  }

  final homeOverview = homeData.overview;

  if (realtimeOverview.hasValue) {
    final realtime = realtimeOverview.value!;
    return AsyncValue.data(
      SystemStatus(
        serverName: homeOverview.serverName ?? realtime.serverName,
        dsmVersion: homeOverview.dsmVersion ?? realtime.dsmVersion,
        cpuUsage: realtime.cpuUsage,
        cpuUserUsage: realtime.cpuUserUsage,
        cpuSystemUsage: realtime.cpuSystemUsage,
        cpuIoWaitUsage: realtime.cpuIoWaitUsage,
        load1: realtime.load1,
        load5: realtime.load5,
        load15: realtime.load15,
        memoryUsage: realtime.memoryUsage,
        memoryTotalBytes: realtime.memoryTotalBytes,
        memoryUsedBytes: realtime.memoryUsedBytes,
        memoryBufferBytes: realtime.memoryBufferBytes,
        memoryCachedBytes: realtime.memoryCachedBytes,
        memoryAvailableBytes: realtime.memoryAvailableBytes,
        storageUsage: realtime.storageUsage > 0 ? realtime.storageUsage : homeOverview.storageUsage,
        networkUploadBytesPerSecond: realtime.networkUploadBytesPerSecond,
        networkDownloadBytesPerSecond: realtime.networkDownloadBytesPerSecond,
        diskReadBytesPerSecond: realtime.diskReadBytesPerSecond,
        diskWriteBytesPerSecond: realtime.diskWriteBytesPerSecond,
        networkInterfaces: realtime.networkInterfaces,
        disks: realtime.disks,
        volumePerformances: realtime.volumePerformances,
        volumes: homeOverview.volumes,
        modelName: homeOverview.modelName ?? realtime.modelName,
        serialNumber: homeOverview.serialNumber ?? realtime.serialNumber,
        uptimeText: homeOverview.uptimeText ?? realtime.uptimeText,
      ),
    );
  }

  return AsyncValue.data(homeOverview);
});
