import '../../core/utils/server_mapper.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../api/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._authApi);

  final AuthApi _authApi;

  String? _mergeCookieHeaders(String? a, String? b) {
    final parts = <String>[];
    if (a != null && a.isNotEmpty) {
      parts.addAll(a.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (b != null && b.isNotEmpty) {
      parts.addAll(b.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (parts.isEmpty) return null;

    final cookieMap = <String, String>{};
    for (final part in parts) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final key = part.substring(0, idx).trim();
      final value = part.substring(idx + 1).trim();
      cookieMap[key] = value;
    }

    if (cookieMap.isEmpty) return null;
    return cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  @override
  Future<NasVersionInfo> probeVersion({
    required NasServer server,
  }) async {
    final model = ServerMapper.toModel(server);
    final info = await _authApi.probeVersion(server: model);
    return NasVersionInfo(
      major: info.major,
      minor: info.minor,
      build: info.build,
      productVersion: info.productVersion,
      fullVersionString: info.fullVersionString,
      isDsm7OrAbove: info.isDsm7OrAbove,
    );
  }

  @override
  Future<NasSession> refreshRealtimeSession({
    required NasServer server,
    required NasSession session,
  }) async {
    final model = ServerMapper.toModel(server);
    final result = await _authApi.refreshRealtimeSession(
      server: model,
      sid: session.sid,
    );

    final mergedCookieHeader = _mergeCookieHeaders(
      session.cookieHeader,
      result.cookieHeader,
    );

    return NasSession(
      serverId: server.id,
      sid: result.sid,
      synoToken: result.synoToken ?? session.synoToken,
      cookieHeader: mergedCookieHeader ?? session.cookieHeader,
      requestHashSeed: result.requestHashSeed ?? session.requestHashSeed,
      authToken: result.authToken ?? session.authToken,
      requestNonce: session.requestNonce,
    );
  }

  @override
  Future<NasSession> login({
    required NasServer server,
    required String username,
    required String password,
  }) async {
    final model = ServerMapper.toModel(server);

    final result = await _authApi.login(
      server: model,
      username: username,
      password: password,
    );

    return NasSession(
      serverId: server.id,
      sid: result.sid,
      synoToken: result.synoToken,
      cookieHeader: result.cookieHeader,
      requestHashSeed: result.requestHashSeed,
      authToken: result.authToken,
    );
  }

  @override
  Future<void> logout({
    required NasServer server,
    required NasSession session,
  }) async {
    final model = ServerMapper.toModel(server);
    await _authApi.logout(server: model, sid: session.sid);
  }
}
