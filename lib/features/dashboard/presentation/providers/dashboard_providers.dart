import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
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
  return text.contains('authentication error') ||
      text.contains('unauthorized') ||
      text.contains('invalid sid') ||
      text.contains('expired') ||
      text.contains('119');
}

bool _looksLikeRealtimeAuthFailure(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('synotoken') ||
      text.contains('token') ||
      text.contains('request_webapi') ||
      text.contains('websocket') ||
      text.contains('socket') ||
      text.contains('auth');
}

Future<void> _handleSessionExpired(Ref ref) async {
  await ref.read(clearSessionProvider)(markExpired: true);

  final context = appNavigatorKey.currentContext;
  if (context != null) {
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

  final source = ref.read(systemRepositoryProvider).watchOverview(
        server: server,
        session: session,
      );

  late final StreamController<SystemStatus> controller;
  StreamSubscription<SystemStatus>? subscription;

  controller = StreamController<SystemStatus>(
    onListen: () {
      subscription = source.listen(
        controller.add,
        onError: (error, stackTrace) async {
          if (_isSessionExpiredError(error)) {
            await _handleSessionExpired(ref);
            controller.addError(error, stackTrace);
            return;
          }

          if (_looksLikeRealtimeAuthFailure(error)) {
            try {
              await ref.read(refreshRealtimeSessionProvider)();
              final retried = ref.read(systemRepositoryProvider).watchOverview(
                    server: ref.read(currentServerProvider)!,
                    session: ref.read(currentSessionProvider)!,
                  );

              await subscription?.cancel();
              subscription = retried.listen(
                controller.add,
                onError: (retryError, retryStackTrace) async {
                  if (_isSessionExpiredError(retryError)) {
                    await _handleSessionExpired(ref);
                  }
                  controller.addError(retryError, retryStackTrace);
                },
                onDone: controller.close,
                cancelOnError: false,
              );
              return;
            } catch (refreshError, refreshStackTrace) {
              if (_isSessionExpiredError(refreshError)) {
                await _handleSessionExpired(ref);
              }
              controller.addError(refreshError, refreshStackTrace);
              return;
            }
          }

          controller.addError(error, stackTrace);
        },
        onDone: controller.close,
        cancelOnError: false,
      );
    },
    onCancel: () async {
      await subscription?.cancel();
    },
  );

  ref.onDispose(() async {
    await subscription?.cancel();
    await controller.close();
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
        memoryUsage: realtime.memoryUsage,
        storageUsage: base?.storageUsage ?? realtime.storageUsage,
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
