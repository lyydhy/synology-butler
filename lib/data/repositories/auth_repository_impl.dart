import '../../core/utils/server_mapper.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../api/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._authApi);

  final AuthApi _authApi;

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
