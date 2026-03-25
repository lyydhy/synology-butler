import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'current_connection_store.dart';
import 'request_log_interceptor.dart';
import 'session_recovery_bridge.dart';

typedef SessionRecoveryCallback = Future<Map<String, String?>> Function();

class SessionRecoveryInterceptor extends Interceptor {
  SessionRecoveryInterceptor({this.ignoreBadCertificate = false});

  final bool ignoreBadCertificate;

  static const _retriedKey = 'session_recovery_retried';

  // ─────────────────────────────────────────────────────────────
  //  Private helpers
  // ─────────────────────────────────────────────────────────────

  bool _shouldSkipRecovery(RequestOptions options) {
    final path = options.path.toLowerCase();
    final api = options.queryParameters['api']?.toString() ??
        (options.data is Map ? options.data['api']?.toString() : null);
    final method = options.queryParameters['method']?.toString() ??
        (options.data is Map ? options.data['method']?.toString() : null);

    if (api == 'SYNO.API.Auth') return true;
    if (path.contains('/webapi/entry.cgi/syno.api.auth')) return true;
    if (path.contains('/webapi/auth.cgi')) return true;
    if (method == 'login' || method == 'token') return true;
    return false;
  }

  bool _isSessionExpiredPayload(dynamic data) {
    if (data is! Map || data['success'] != false) return false;
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
    final headers = Map<String, dynamic>.from(options.headers);
    // Do NOT copy Content-Type via headers — it is already set at BaseOptions level
    // via the contentType param. Copying both triggers Dio assertion:
    // "You cannot set both contentType param and a content-type header"
    headers.remove('Content-Type');

    return options.copyWith(
      path: options.path,
      method: options.method,
      baseUrl: options.baseUrl,
      data: options.data,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      headers: headers,
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

  // ─────────────────────────────────────────────────────────────
  //  Interceptor hooks
  // ─────────────────────────────────────────────────────────────

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final options = response.requestOptions;

    if (_shouldSkipRecovery(options)) {
      handler.next(response);
      return;
    }
    if (!_isSessionExpiredPayload(response.data)) {
      handler.next(response);
      return;
    }
    if (!_canRetry(options)) {
      handler.next(response);
      return;
    }

    try {
      Map<String, String?> recovered = {};

      if (SessionRecoveryBridge.callback != null) {
        recovered = await SessionRecoveryBridge.callback!();
      }

      final retryOptions = _cloneOptions(options);
      _applyRecoveredSession(retryOptions, recovered);
      final retryDio = _buildRetryDio(options);
      final retryResponse = await retryDio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(response);
    }
  }
}
