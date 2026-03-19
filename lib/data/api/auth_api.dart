import '../models/nas_server_model.dart';

abstract class AuthApi {
  Future<String> login({
    required NasServerModel server,
    required String username,
    required String password,
  });

  Future<void> logout({
    required NasServerModel server,
    required String sid,
  });
}
