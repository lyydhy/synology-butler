import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/local_app_logger.dart';

class RequestLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_logStartAt'] = DateTime.now().millisecondsSinceEpoch;
    unawaited(
      LocalAppLogger.log(
        level: 'info',
        module: 'network',
        event: 'request',
        extra: {
          'method': options.method,
          'uri': options.uri.toString(),
          'query': options.queryParameters.toString(),
        },
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startedAt = response.requestOptions.extra['_logStartAt'] as int?;
    final durationMs = startedAt == null ? null : DateTime.now().millisecondsSinceEpoch - startedAt;

    unawaited(
      LocalAppLogger.log(
        level: 'info',
        module: 'network',
        event: 'response',
        extra: {
          'method': response.requestOptions.method,
          'uri': response.requestOptions.uri.toString(),
          'statusCode': response.statusCode,
          if (durationMs != null) 'durationMs': durationMs,
        },
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startedAt = err.requestOptions.extra['_logStartAt'] as int?;
    final durationMs = startedAt == null ? null : DateTime.now().millisecondsSinceEpoch - startedAt;

    unawaited(
      LocalAppLogger.log(
        level: 'error',
        module: 'network',
        event: 'error',
        message: err.toString(),
        extra: {
          'method': err.requestOptions.method,
          'uri': err.requestOptions.uri.toString(),
          'dioType': err.type.name,
          'statusCode': err.response?.statusCode,
          if (durationMs != null) 'durationMs': durationMs,
          if (err.error != null) 'error': err.error.toString(),
        },
      ),
    );
    handler.next(err);
  }
}
