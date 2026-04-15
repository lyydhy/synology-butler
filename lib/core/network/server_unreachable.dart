import 'dart:async';

import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/utils/local_app_logger.dart';
import '../../core/utils/toast.dart';
import 'current_connection_store.dart';

/// Global flag to prevent multiple redirects within the same interceptor chain.
bool _redirectInProgress = false;

/// Resets the redirect flag (called after successful re-login).
void resetUnreachableState() {
  _redirectInProgress = false;
}

/// Interceptor that detects when the NAS server is unreachable
/// (WAN trying to access LAN IP) and triggers a redirect to login.
class UnreachableRedirectInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final uri = err.requestOptions.uri;
    final path = uri.path;
    final host = uri.host;
    final errorType = err.type.name;

    // Skip login/auth/logout endpoints
    if (path.contains('auth') || path.contains('login') || path.contains('logout')) {
      handler.next(err);
      return;
    }

    final isInternal = _isInternalServerAddress(host);
    final isLanError = _isLanAccessError(err);

    unawaited(LocalAppLogger.log(
      level: 'warn',
      module: 'network',
      event: 'unreachable_check',
      message: 'API error: uri=${uri.toString()} host=$host type=$errorType isInternal=$isInternal isLanError=$isLanError path=$path',
      extra: {
        'uri': uri.toString(),
        'host': host,
        'errorType': errorType,
        'isInternal': isInternal,
        'isLanError': isLanError,
        'path': path,
        'redirectInProgress': _redirectInProgress,
      },
    ));

    if (isLanError && !_redirectInProgress) {
      _redirectInProgress = true;
      unawaited(LocalAppLogger.log(
        level: 'info',
        module: 'network',
        event: 'unreachable_trigger',
        message: 'Redirecting to /login (host=$host)',
      ));
      Toast.warning('网络不可达，正在返回登录页...');
      appNavigatorKey.currentContext?.go('/login');
    }

    handler.next(err);
  }

  bool _isLanAccessError(DioException err) {
    if (err.type == DioExceptionType.connectionError) return true;
    if (err.type == DioExceptionType.connectionTimeout) return true;
    // unknown type + internal server in connectionStore → likely proxy/networking issue
    // to internal NAS while on WAN (e.g. proxy unreachable from device's network)
    if (err.type == DioExceptionType.unknown && _isInternalServerAddress('')) return true;
    return false;
  }

  bool _isInternalServerAddress(String host) {
    // Use the error host first (actual destination of the request).
    // When going through a proxy, this will be the proxy IP, so also
    // check connectionStore.server.host as fallback.
    if (_isPrivateIp(host)) return true;
    final serverHost = connectionStore.server?.host;
    if (serverHost != null && _isPrivateIp(serverHost)) return true;
    return false;
  }

  bool _isPrivateIp(String host) {
    if (host.isEmpty) return false;
    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        (host.startsWith('172.') && _is172Internal(host));
  }

  bool _is172Internal(String host) {
    final parts = host.split('.');
    if (parts.length < 2) return false;
    final second = int.tryParse(parts[1]) ?? 0;
    return second >= 16 && second <= 31;
  }
}
