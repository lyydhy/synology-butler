import '../../domain/entities/nas_server.dart';

class ServerUrlHelper {
  static String normalizeHost(String raw) {
    var value = raw.trim();
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static String normalizeBasePath(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();
    return value.startsWith('/') ? value : '/$value';
  }

  static String buildBaseUrl(NasServer server) {
    final scheme = server.https ? 'https' : 'http';
    final host = normalizeHost(server.host);
    final basePath = normalizeBasePath(server.basePath);
    return '$scheme://$host:${server.port}$basePath';
  }
}
