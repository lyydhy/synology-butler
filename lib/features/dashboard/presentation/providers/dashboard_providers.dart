import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../data/api/system_api.dart';
import '../../../../data/repositories/system_repository_impl.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../domain/repositories/system_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'dashboard_realtime_global.dart';

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

final dashboardBaseOverviewProvider = FutureProvider<SystemStatus>((ref) async {
  try {
    return await ref.read(systemRepositoryProvider).fetchOverview();
  } catch (error) {
    if (_isSessionExpiredError(error)) {
      await _handleSessionExpired(ref);
    }
    rethrow;
  }
});

final dashboardOverviewSafeProvider = Provider<AsyncValue<SystemStatus?>>((ref) {
  final baseOverview = ref.watch(dashboardBaseOverviewProvider);
  final realtimeOverview = ref.watch(globalRealtimeOverviewProvider);

  if (realtimeOverview.hasValue) {
    final realtime = realtimeOverview.value!;
    final base = baseOverview.valueOrNull;

    return AsyncValue.data(
      SystemStatus(
        serverName: base?.serverName ?? realtime.serverName,
        dsmVersion: base?.dsmVersion ?? realtime.dsmVersion,
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
        storageUsage: realtime.storageUsage > 0 ? realtime.storageUsage : (base?.storageUsage ?? 0),
        networkUploadBytesPerSecond: realtime.networkUploadBytesPerSecond,
        networkDownloadBytesPerSecond: realtime.networkDownloadBytesPerSecond,
        diskReadBytesPerSecond: realtime.diskReadBytesPerSecond,
        diskWriteBytesPerSecond: realtime.diskWriteBytesPerSecond,
        networkInterfaces: realtime.networkInterfaces,
        disks: realtime.disks,
        volumePerformances: realtime.volumePerformances,
        volumes: realtime.volumes.isNotEmpty ? realtime.volumes : (base?.volumes ?? const []),
        modelName: base?.modelName ?? realtime.modelName,
        serialNumber: base?.serialNumber ?? realtime.serialNumber,
        uptimeText: base?.uptimeText ?? realtime.uptimeText,
      ),
    );
  }

  if (baseOverview.hasValue) {
    return AsyncValue.data(baseOverview.value);
  }

  if (baseOverview.isLoading) {
    return const AsyncValue.loading();
  }

  return const AsyncValue.data(null);
});
