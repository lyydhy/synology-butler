import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'request_log_interceptor.dart';
import 'session_recovery_bridge.dart';
import 'session_recovery_interceptor.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    bool ignoreBadCertificate = false,
    SessionRecoveryCallback? onRecoverSession,
    bool enableSessionRecovery = true,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            contentType: Headers.formUrlEncodedContentType,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['__dio__'] = dio;
          handler.next(options);
        },
      ),
    );
    dio.interceptors.add(RequestLogInterceptor());
    final recoveryCallback = onRecoverSession ?? SessionRecoveryBridge.callback;
    if (enableSessionRecovery && recoveryCallback != null) {
      dio.interceptors.add(SessionRecoveryInterceptor(recoveryCallback));
    }

    final adapter = dio.httpClientAdapter;
    if (ignoreBadCertificate && adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (_, __, ___) => true;
        return client;
      };
    }
  }

  final Dio dio;
}
