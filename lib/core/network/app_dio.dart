import 'package:dio/dio.dart';

import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import 'current_connection_store.dart';
import 'dio_client.dart';
import 'request_log_interceptor.dart';
import 'session_attach_interceptor.dart';
import 'session_recovery_interceptor.dart';

class AppDioFactory {
  AppDioFactory._();

  static final CurrentConnectionStore connectionStore = CurrentConnectionStore.instance;
  static Dio? _businessDio;

  static Dio businessDio({bool ignoreBadCertificate = false}) {
    return _businessDio ??= DioClient(
      baseUrl: 'http://127.0.0.1',
      ignoreBadCertificate: ignoreBadCertificate,
      interceptors: [
        SessionAttachInterceptor(connectionStore),
        RequestLogInterceptor(),
        SessionRecoveryInterceptor(ignoreBadCertificate: ignoreBadCertificate),
      ],
    ).dio;
  }

  static void setConnection({
    required NasServer server,
    required NasSession session,
  }) {
    connectionStore.setConnection(server: server, session: session);
  }

  static void setServer(NasServer? server) {
    connectionStore.setServer(server);
  }

  static void setSession(NasSession? session) {
    connectionStore.setSession(session);
  }

  static void clearSession() {
    connectionStore.clearSession();
  }

  static void clearAll() {
    connectionStore.clearAll();
  }
}
