import '../models/nas_server_model.dart';

class AuthLoginResult {
  final String sid;
  final String? synoToken;
  final String? cookieHeader;

  const AuthLoginResult({
    required this.sid,
    this.synoToken,
    this.cookieHeader,
  });
}

abstract class AuthApi {
  Future<AuthLoginResult> login({
    required NasServerModel server,
    required String username,
    required String password,
  });

  Future<void> logout({
    required NasServerModel server,
    required String sid,
  });
}
