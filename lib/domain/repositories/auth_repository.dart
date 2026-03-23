import '../entities/nas_server.dart';
import '../entities/nas_session.dart';

class NasVersionInfo {
  final String? major;
  final String? minor;
  final String? build;
  final String? productVersion;
  final String? fullVersionString;
  final bool isDsm7OrAbove;

  const NasVersionInfo({
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

abstract class AuthRepository {
  Future<NasVersionInfo> probeVersion({
    required NasServer server,
  });

  Future<NasSession> refreshRealtimeSession({
    required NasServer server,
    required NasSession session,
  });

  Future<NasSession> refreshSynoToken({
    required NasServer server,
    required NasSession session,
  });

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
