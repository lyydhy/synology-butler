import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../core/network/realtime_reconnect_bridge.dart';
import '../../../../data/api/system_api.dart';
import '../../../../data/repositories/system_repository_impl.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../domain/repositories/system_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final globalSystemApiProvider = Provider<SystemApi>((ref) {
  final server = connectionStore.server;
  return DsmSystemApi(ignoreBadCertificate: server?.ignoreBadCertificate ?? false);
});

final globalSystemRepositoryProvider = Provider<SystemRepository>((ref) {
  return SystemRepositoryImpl(ref.read(globalSystemApiProvider));
});

bool looksLikeRealtimeAuthFailure(Object error) {
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

bool isSessionExpiredError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('session expired') ||
      text.contains('login required') ||
      text.contains('unauthorized') ||
      text.contains('invalid sid') ||
      text.contains('expired') ||
      text.contains('119');
}

final globalRealtimeOverviewProvider = StreamProvider<SystemStatus>((ref) {
  late final StreamController<SystemStatus> controller;
  StreamSubscription<SystemStatus>? subscription;
  late final Future<void> Function() startStream;

  int consecutiveFailures = 0;
  Timer? retryTimer;
  var retryAttempt = 0;

  bool isReadyForRealtime() {
    final server = connectionStore.server;
    final session = connectionStore.session;
    final token = session?.synoToken;
    return server != null &&
        session != null &&
        session.sid.isNotEmpty &&
        token != null &&
        token.isNotEmpty;
  }

  Duration computeBackoff(int attempt) {
    const seconds = [1, 2, 4, 8, 15];
    final index = attempt.clamp(0, seconds.length - 1);
    return Duration(seconds: seconds[index]);
  }

  void scheduleRetry() {
    if (controller.isClosed || retryTimer != null) return;
    final delay = computeBackoff(retryAttempt);
    retryAttempt += 1;
    retryTimer = Timer(delay, () {
      retryTimer = null;
      unawaited(startStream());
    });
  }

  startStream = () async {
    if (controller.isClosed) return;

    if (!isReadyForRealtime()) {
      scheduleRetry();
      return;
    }

    try {
      final source = ref.read(globalSystemRepositoryProvider).watchOverview();

      await subscription?.cancel();
      subscription = source.listen(
        (value) {
          consecutiveFailures = 0;
          retryAttempt = 0;
          controller.add(value);
        },
        onError: (error, stackTrace) async {
          consecutiveFailures += 1;
          final shouldSurfaceError = consecutiveFailures >= 3;
          if (isSessionExpiredError(error)) {
            try {
              await ref.read(recoverSessionProvider)();
              consecutiveFailures = 0;
              retryAttempt = 0;
              await subscription?.cancel();
              if (!controller.isClosed) {
                unawaited(startStream());
              }
              return;
            } catch (_) {}
          }
          if (shouldSurfaceError) {
            controller.addError(error, stackTrace);
          }
          scheduleRetry();
        },
        onDone: () {
          if (!controller.isClosed) {
            scheduleRetry();
          }
        },
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      consecutiveFailures += 1;
      if (consecutiveFailures >= 3) {
        controller.addError(error, stackTrace);
      }
      scheduleRetry();
    }
  };

  controller = StreamController<SystemStatus>(
    onListen: () {
      unawaited(startStream());
    },
    onCancel: () async {
      await subscription?.cancel();
    },
  );

  Future<void> reconnectCallback() async {
    if (controller.isClosed) return;
    final latestSession = connectionStore.session;
    final sidPreview = latestSession == null
        ? 'missing'
        : (latestSession.sid.length > 8 ? latestSession.sid.substring(0, 8) : latestSession.sid);
    final synoTokenPreview = latestSession?.synoToken == null || latestSession!.synoToken!.isEmpty
        ? 'missing'
        : (latestSession.synoToken!.length > 8 ? latestSession.synoToken!.substring(0, 8) : latestSession.synoToken!);
    debugPrint('[Realtime][Reconnect][Global] restart stream with latest session sid=$sidPreview token=$synoTokenPreview');
    await startStream();
  }

  RealtimeReconnectBridge.callback = reconnectCallback;

  ref.onDispose(() async {
    if (identical(RealtimeReconnectBridge.callback, reconnectCallback)) {
      RealtimeReconnectBridge.callback = null;
    }
    retryTimer?.cancel();
    await subscription?.cancel();
    if (!controller.isClosed) {
      await controller.close();
    }
  });

  return controller.stream;
});
