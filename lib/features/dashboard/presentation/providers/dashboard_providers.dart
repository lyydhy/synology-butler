import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/network/realtime_reconnect_bridge.dart';
import '../../../../data/api/system_api.dart';
import '../../../../data/repositories/system_repository_impl.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../domain/repositories/system_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final systemApiProvider = Provider<SystemApi>((ref) => DsmSystemApi());

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

bool _looksLikeRealtimeAuthFailure(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('realtime authentication error') ||
      text.contains('bootstrap timeout') ||
      text.contains('request_webapi') ||
      text.contains('websocket') ||
      text.contains('socket') ||
      text.contains('synotoken') ||
      (text.contains('token') && text.contains('realtime')) ||
      (text.contains('auth') && text.contains('realtime'));
}

Future<void> _handleSessionExpired(Ref ref) async {
  await ref.read(clearSessionProvider)(markExpired: true);

  final context = appNavigatorKey.currentContext;
  if (context != null && context.mounted) {
    GoRouter.of(context).go('/login');
  }
}

final dashboardBaseOverviewProvider = FutureProvider<SystemStatus>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  try {
    return await ref.read(systemRepositoryProvider).fetchOverview(
          server: server,
          session: session,
        );
  } catch (error) {
    if (_isSessionExpiredError(error)) {
      await _handleSessionExpired(ref);
    }
    rethrow;
  }
});

final dashboardRealtimeOverviewProvider = StreamProvider<SystemStatus>((ref) {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  late final StreamController<SystemStatus> controller;
  StreamSubscription<SystemStatus>? subscription;

  Future<void> startStream({bool allowRefresh = true}) async {
    final activeServer = ref.read(currentServerProvider);
    final activeSession = ref.read(currentSessionProvider);
    if (activeServer == null || activeSession == null) {
      controller.addError(Exception('No active NAS session'));
      return;
    }

    final source = ref.read(systemRepositoryProvider).watchOverview(
          server: activeServer,
          session: activeSession,
        );

    await subscription?.cancel();
    subscription = source.listen(
      controller.add,
      onError: (error, stackTrace) async {
        if (_looksLikeRealtimeAuthFailure(error)) {
          controller.addError(error, stackTrace);
          return;
        }

        if (_isSessionExpiredError(error)) {
          await _handleSessionExpired(ref);
        }
        controller.addError(error, stackTrace);
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
      },
      cancelOnError: false,
    );
  }

  controller = StreamController<SystemStatus>(
    onListen: () {
      unawaited(startStream());
    },
    onCancel: () async {
      await subscription?.cancel();
    },
  );

  final reconnectCallback = () async {
    if (controller.isClosed) return;
    final latestSession = ref.read(currentSessionProvider);
    final sidPreview = latestSession == null
        ? 'missing'
        : (latestSession.sid.length > 8 ? latestSession.sid.substring(0, 8) : latestSession.sid);
    final synoTokenPreview = latestSession?.synoToken == null || latestSession!.synoToken!.isEmpty
        ? 'missing'
        : (latestSession.synoToken!.length > 8 ? latestSession.synoToken!.substring(0, 8) : latestSession.synoToken!);
    // ignore: avoid_print
    print('[Realtime][Reconnect] restart stream with latest session sid=$sidPreview token=$synoTokenPreview');
    await startStream(allowRefresh: false);
  };
  RealtimeReconnectBridge.callback = reconnectCallback;

  ref.onDispose(() async {
    if (identical(RealtimeReconnectBridge.callback, reconnectCallback)) {
      RealtimeReconnectBridge.callback = null;
    }
    await subscription?.cancel();
    if (!controller.isClosed) {
      await controller.close();
    }
  });

  return controller.stream;
});

final dashboardOverviewSafeProvider = Provider<AsyncValue<SystemStatus?>>((ref) {
  final baseOverview = ref.watch(dashboardBaseOverviewProvider);
  final realtimeOverview = ref.watch(dashboardRealtimeOverviewProvider);

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
        storageUsage: base?.storageUsage ?? realtime.storageUsage,
        networkUploadBytesPerSecond: realtime.networkUploadBytesPerSecond,
        networkDownloadBytesPerSecond: realtime.networkDownloadBytesPerSecond,
        diskReadBytesPerSecond: realtime.diskReadBytesPerSecond,
        diskWriteBytesPerSecond: realtime.diskWriteBytesPerSecond,
        networkInterfaces: realtime.networkInterfaces,
        disks: realtime.disks,
        volumePerformances: realtime.volumePerformances,
        volumes: base?.volumes ?? const [],
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
