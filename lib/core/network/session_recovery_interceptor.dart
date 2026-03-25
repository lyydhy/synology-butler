import 'package:dio/dio.dart';

typedef SessionRecoveryCallback = Future<Map<String, String?>> Function();

class SessionRecoveryInterceptor extends Interceptor {
  SessionRecoveryInterceptor(this._recoverSession);

  final SessionRecoveryCallback _recoverSession;

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
    if (_shouldSkipRecovery(response.requestOptions) || !_isSessionExpiredPayload(response.data) || !_canRetry(response.requestOptions)) {
      handler.next(response);
      return;
    }

    try {
      final recovered = await _recoverSession();
      final retryOptions = _cloneOptions(response.requestOptions);
      _applyRecoveredSession(retryOptions, recovered);
      final dio = response.requestOptions.extra['__dio__'];
      if (dio is! Dio) {
        handler.next(response);
        return;
      }

      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(response);
    }
  }
}
