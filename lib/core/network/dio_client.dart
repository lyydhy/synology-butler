import 'package:dio/dio.dart';

class DioClient {
  DioClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            contentType: Headers.formUrlEncodedContentType,
          ),
        );

  final Dio dio;
}
