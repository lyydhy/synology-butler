import '../entities/download_task.dart';

abstract class DownloadRepository {
  Future<List<DownloadTask>> listTasks();

  Future<void> createTask({
    required String uri,
  });

  Future<void> pauseTask({
    required String id,
  });

  Future<void> resumeTask({
    required String id,
  });

  Future<void> deleteTask({
    required String id,
  });
}
