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

  Future<void> startStream() async {
    try {
      final source = ref.read(globalSystemRepositoryProvider).watchOverview();

      await subscription?.cancel();
      subscription = source.listen(
        controller.add,
        onError: (error, stackTrace) async {
          controller.addError(error, stackTrace);
          if (isSessionExpiredError(error)) {
            await ref.read(clearSessionProvider)(markExpired: true);
          }
        },
        onDone: () {
          if (!controller.isClosed) {
            controller.close();
          }
        },
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    }
  }

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
    await subscription?.cancel();
    if (!controller.isClosed) {
      await controller.close();
    }
  });

  return controller.stream;
});
