import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import 'current_connection_store.dart';
import 'request_log_interceptor.dart';
import 'server_unreachable.dart';
import 'session_attach_interceptor.dart';
import 'session_recovery_interceptor.dart';

export 'current_connection_store.dart' show connectionStore;

/// Creates a new [Dio] instance configured for DSM API calls.
///
/// Every call creates a fresh instance so that [ignoreBadCertificate]
/// is always respected — do NOT cache the result globally.
Dio businessDio({bool ignoreBadCertificate = false}) {
  return DioClient(
    baseUrl: 'http://127.0.0.1',
    ignoreBadCertificate: ignoreBadCertificate,
    interceptors: [
      SessionAttachInterceptor(connectionStore),
      RequestLogInterceptor(),
      SessionRecoveryInterceptor(ignoreBadCertificate: ignoreBadCertificate),
      UnreachableRedirectInterceptor(),
    ],
  ).dio;
}

/// Convenience helpers delegating to [connectionStore].
void setConnection({required NasServer server, required NasSession session}) {
  connectionStore.setConnection(server: server, session: session);
}

void setServer(NasServer? server) => connectionStore.setServer(server);

void setSession(NasSession? session) => connectionStore.setSession(session);

void clearSession() => connectionStore.clearSession();

void clearAll() => connectionStore.clearAll();

// ─────────────────────────────────────────────────────────────────────────────
//  DioClient
// ─────────────────────────────────────────────────────────────────────────────

/// Thin wrapper around [Dio] that applies consistent defaults and interceptors.
class DioClient {
  DioClient({
    required String baseUrl,
    bool ignoreBadCertificate = false,
    List<Interceptor>? interceptors,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            contentType: Headers.formUrlEncodedContentType,
          ),
        ) {
    dio.interceptors.addAll(interceptors ?? [
      RequestLogInterceptor(),
      SessionRecoveryInterceptor(ignoreBadCertificate: ignoreBadCertificate),
      UnreachableRedirectInterceptor(),
    ]);

    if (ignoreBadCertificate) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter?;
      if (adapter != null) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.badCertificateCallback = (_, __, ___) => true;
          return client;
        };
      }
    }
  }

  final Dio dio;
}
