import '../models/nas_server_model.dart';

class AuthLoginResult {
  final String sid;
  final String? synoToken;
  final String? cookieHeader;
  final String? requestHashSeed;
  final String? authToken;
  final String? noiseIkMessage;

  const AuthLoginResult({
    required this.sid,
    this.synoToken,
    this.cookieHeader,
    this.requestHashSeed,
    this.authToken,
    this.noiseIkMessage,
  });
}

class DsmVersionInfo {
  final String? major;
  final String? minor;
  final String? build;
  final String? productVersion;
  final String? fullVersionString;
  final bool isDsm7OrAbove;

  const DsmVersionInfo({
    required this.major,
    required this.minor,
    required this.build,
    required this.productVersion,
    required this.fullVersionString,
    required this.isDsm7OrAbove,
  });

  String get displayText {
    if (fullVersionString != null && fullVersionString!.trim().isNotEmpty) {
      return fullVersionString!.trim();
    }
    if (productVersion != null && productVersion!.trim().isNotEmpty) {
      return 'DSM ${productVersion!.trim()}';
    }
    if (major != null && minor != null) {
      return 'DSM $major.$minor';
    }
    if (major != null) {
      return 'DSM $major';
    }
    return 'DSM 未知版本';
  }
}

abstract class AuthApi {
  Future<DsmVersionInfo> probeVersion({
    required NasServerModel server,
  });

  Future<AuthLoginResult> refreshRealtimeSession({
    required NasServerModel server,
    required String sid,
  });

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
