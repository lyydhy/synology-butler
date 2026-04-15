import 'package:dio/dio.dart';

/// Global flag to prevent multiple redirects within the same interceptor chain.
bool _redirectInProgress = false;

/// Notifies the app to redirect to /login when the server is unreachable.
/// Set by UnreachableRedirectInterceptor or logoutProvider.
void markServerUnreachable() {
  if (_redirectInProgress) return;
  _redirectInProgress = true;
}

/// Returns true if a redirect is already in progress.
bool get isRedirectInProgress => _redirectInProgress;

/// Resets the redirect flag (called after successful re-login).
void resetUnreachableState() {
  _redirectInProgress = false;
}

/// Interceptor that detects when the NAS server is unreachable
/// (WAN trying to access LAN IP) and triggers a redirect to login.
/// Call [markServerUnreachable] to signal the app to redirect.
class UnreachableRedirectInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Skip login/auth/logout endpoints
    final path = err.requestOptions.uri.path;
    if (path.contains('auth') || path.contains('login') || path.contains('logout')) {
      handler.next(err);
      return;
    }

    if (_isLanAccessError(err) && !_redirectInProgress) {
      markServerUnreachable();
    }

    handler.next(err);
  }

  bool _isLanAccessError(DioException err) {
    if (err.type == DioExceptionType.connectionError) return true;
    if (err.type == DioExceptionType.connectionTimeout && _isInternalServerAddress(err)) return true;
    return false;
  }

  bool _isInternalServerAddress(DioException err) {
    final host = err.requestOptions.uri.host;
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
