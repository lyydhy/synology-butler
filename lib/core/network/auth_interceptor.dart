import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.sid);

  final String? sid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (sid != null && sid!.isNotEmpty) {
      options.queryParameters = {
        ...options.queryParameters,
        '_sid': sid,
      };
    }
    handler.next(options);
  }
}
