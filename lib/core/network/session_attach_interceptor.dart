import 'package:dio/dio.dart';

import '../../core/utils/server_url_helper.dart';
import 'current_connection_store.dart';

class SessionAttachInterceptor extends Interceptor {
  SessionAttachInterceptor(this._store);

  final CurrentConnectionStore _store;

  bool _shouldSkip(RequestOptions options) {
    final path = options.path.toLowerCase();
    final queryApi = options.queryParameters['api']?.toString();
    final queryMethod = options.queryParameters['method']?.toString();
    final body = options.data;
    final bodyApi = body is Map ? body['api']?.toString() : null;
    final bodyMethod = body is Map ? body['method']?.toString() : null;
    final api = queryApi ?? bodyApi;
    final method = queryMethod ?? bodyMethod;

    if (api == 'SYNO.API.Auth') return true;
    if (path.contains('/webapi/entry.cgi/syno.api.auth')) return true;
    if (path.contains('/webapi/auth.cgi')) return true;
    if (method == 'login' || method == 'token' || method == 'logout') return true;
    return false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldSkip(options)) {
      handler.next(options);
      return;
    }

    final server = _store.server;
    final session = _store.session;
    if (server == null || session == null) {
      handler.next(options);
      return;
    }

    options.baseUrl = ServerUrlHelper.buildBaseUrl(server);

    final query = Map<String, dynamic>.from(options.queryParameters);
    query['_sid'] = session.sid;
    options.queryParameters = query;

    if (session.synoToken != null && session.synoToken!.isNotEmpty) {
      options.headers['X-SYNO-TOKEN'] = session.synoToken!;
    }
    if (session.cookieHeader != null && session.cookieHeader!.isNotEmpty) {
      options.headers['Cookie'] = session.cookieHeader!;
    }

    if (options.data is Map<String, dynamic>) {
      final body = Map<String, dynamic>.from(options.data as Map<String, dynamic>);
      body.remove('_sid');
      options.data = body;
    }

    handler.next(options);
  }
}
