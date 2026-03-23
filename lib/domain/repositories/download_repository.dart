import '../entities/download_task.dart';
import '../entities/nas_server.dart';
import '../entities/nas_session.dart';

abstract class DownloadRepository {
  Future<List<DownloadTask>> listTasks({
    required NasServer server,
    required NasSession session,
  });

  Future<void> createTask({
    required NasServer server,
    required NasSession session,
    required String uri,
  });

  Future<void> pauseTask({
    required NasServer server,
    required NasSession session,
    required String id,
  });

  Future<void> resumeTask({
    required NasServer server,
    required NasSession session,
    required String id,
  });

  Future<void> deleteTask({
    required NasServer server,
    required NasSession session,
    required String id,
  });
}
