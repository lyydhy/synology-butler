import '../entities/nas_server.dart';
import '../entities/nas_session.dart';
import '../entities/system_status.dart';

abstract class SystemRepository {
  Future<SystemStatus> fetchOverview({
    required NasServer server,
    required NasSession session,
  });

  Stream<SystemStatus> watchOverview({
    required NasServer server,
    required NasSession session,
  });
}
