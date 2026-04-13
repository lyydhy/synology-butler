import '../entities/download_task.dart';

abstract class DownloadRepository {
  Future<List<DownloadTask>> listTasks();

  Future<List<String>> createTask({
    required List<String> urls,
    String destination = 'Download',
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
