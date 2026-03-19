import '../../core/utils/server_mapper.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../api/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._authApi);

  final AuthApi _authApi;

  @override
  Future<NasSession> login({
    required NasServer server,
    required String username,
    required String password,
  }) async {
    final model = ServerMapper.toModel(server);

    final sid = await _authApi.login(
      server: model,
      username: username,
      password: password,
    );

    return NasSession(serverId: server.id, sid: sid);
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
