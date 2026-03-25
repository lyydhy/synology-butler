import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'request_log_interceptor.dart';
import 'session_recovery_bridge.dart';

// ignore: avoid_print
void _recoveryLog(String message) => print(message);

typedef SessionRecoveryCallback = Future<Map<String, String?>> Function();

class SessionRecoveryInterceptor extends Interceptor {
  SessionRecoveryInterceptor({this.ignoreBadCertificate = false});

  final bool ignoreBadCertificate;

  static const _retriedKey = 'session_recovery_retried';

  bool _shouldSkipRecovery(RequestOptions options) {
    final path = options.path.toLowerCase();
    final queryApi = options.queryParameters['api']?.toString();
    final queryMethod = options.queryParameters['method']?.toString();
    final body = options.data;
    final bodyApi = body is Map ? body['api']?.toString() : null;
    final bodyMethod = body is Map ? body['method']?.toString() : null;
    final api = queryApi ?? bodyApi;
    final method = queryMethod ?? bodyMethod;

    if (api == 'SYNO.API.Auth') {
      return true;
    }
    if (path.contains('/webapi/entry.cgi/syno.api.auth')) {
      return true;
    }
    if (path.contains('/webapi/auth.cgi')) {
      return true;
    }
    if (method == 'login' || method == 'token') {
      return true;
    }
    return false;
  }

  bool _isSessionExpiredPayload(dynamic data) {
    if (data is! Map) return false;
    if (data['success'] != false) return false;
    final error = data['error'];
    if (error is! Map) return false;
    final code = int.tryParse(error['code']?.toString() ?? '');
    return code == 119;
  }

  bool _canRetry(RequestOptions options) {
    if (options.extra[_retriedKey] == true) return false;
    if (options.responseType == ResponseType.stream) return false;
    return true;
  }

  RequestOptions _cloneOptions(RequestOptions options) {
    return options.copyWith(
      path: options.path,
      method: options.method,
      baseUrl: options.baseUrl,
      data: options.data,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      headers: Map<String, dynamic>.from(options.headers),
      extra: {
        ...options.extra,
        _retriedKey: true,
      },
      contentType: options.contentType,
      responseType: options.responseType,
      followRedirects: options.followRedirects,
      listFormat: options.listFormat,
      maxRedirects: options.maxRedirects,
      persistentConnection: options.persistentConnection,
      receiveDataWhenStatusError: options.receiveDataWhenStatusError,
      receiveTimeout: options.receiveTimeout,
      requestEncoder: options.requestEncoder,
      responseDecoder: options.responseDecoder,
      sendTimeout: options.sendTimeout,
      validateStatus: options.validateStatus,
    );
  }

  Dio _buildRetryDio(RequestOptions options) {
    final dio = Dio(
      BaseOptions(
        baseUrl: options.baseUrl,
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
        contentType: options.contentType,
        responseType: options.responseType,
        followRedirects: options.followRedirects,
        listFormat: options.listFormat,
        maxRedirects: options.maxRedirects,
        persistentConnection: options.persistentConnection,
        receiveDataWhenStatusError: options.receiveDataWhenStatusError,
        validateStatus: options.validateStatus,
      ),
    );
    dio.interceptors.add(RequestLogInterceptor());

    final adapter = dio.httpClientAdapter;
    if (ignoreBadCertificate && adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (_, __, ___) => true;
        return client;
      };
    }

    return dio;
  }

  void _applyRecoveredSession(RequestOptions options, Map<String, String?> session) {
    final sid = session['sid'];
    final synoToken = session['synoToken'];
    final cookieHeader = session['cookieHeader'];

    if (sid != null && sid.isNotEmpty) {
      options.queryParameters = {
        ...options.queryParameters,
        '_sid': sid,
      };
    }

    if (synoToken != null && synoToken.isNotEmpty) {
      options.headers['X-SYNO-TOKEN'] = synoToken;
    } else {
      options.headers.remove('X-SYNO-TOKEN');
    }

    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      options.headers['Cookie'] = cookieHeader;
    } else {
      options.headers.remove('Cookie');
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
        _recoveryLog('[SessionRecovery] in 1');
    final options = response.requestOptions;
            _recoveryLog('[SessionRecovery]   in 2');

    final api = options.queryParameters['api']?.toString() ?? (options.data is Map ? options.data['api']?.toString() : null) ?? '-';
            _recoveryLog('[SessionRecovery]  in 3');

    final method = options.queryParameters['method']?.toString() ?? (options.data is Map ? options.data['method']?.toString() : null) ?? '-';
        _recoveryLog('[SessionRecovery]  in 4');

    if (_shouldSkipRecovery(options)) {
      _recoveryLog('[SessionRecovery] skip api=$api method=$method path=${options.path}');
      handler.next(response);
      return;
    }
    if (!_isSessionExpiredPayload(response.data)) {
      handler.next(response);
      return;
    }
    if (!_canRetry(options)) {
      _recoveryLog('[SessionRecovery] not retryable api=$api method=$method path=${options.path}');
      handler.next(response);
      return;
    }

    _recoveryLog('[SessionRecovery] detected expired session api=$api method=$method path=${options.path}');

    try {
      final recoveryCallback = SessionRecoveryBridge.callback;
      if (recoveryCallback == null) {
        throw StateError('Session recovery callback is not registered');
      }
      final recovered = await recoveryCallback();
      final retryOptions = _cloneOptions(options);
      _applyRecoveredSession(retryOptions, recovered);
      final retryDio = _buildRetryDio(options);

      _recoveryLog('[SessionRecovery] retry request api=$api method=$method');
      final retryResponse = await retryDio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (error) {
      _recoveryLog('[SessionRecovery] recover failed api=$api method=$method error=$error');
      handler.next(response);
    }
  }
}
