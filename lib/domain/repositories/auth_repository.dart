import '../entities/nas_server.dart';
import '../entities/nas_session.dart';

abstract class AuthRepository {
  Future<NasSession> login({
    required NasServer server,
    required String username,
    required String password,
  });

  Future<void> logout({
    required NasServer server,
    required NasSession session,
  });
}
