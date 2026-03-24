import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'request_log_interceptor.dart';

class DioClient {
  DioClient({
    required String baseUrl,
    bool ignoreBadCertificate = false,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            contentType: Headers.formUrlEncodedContentType,
          ),
        ) {
    dio.interceptors.add(RequestLogInterceptor());

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
