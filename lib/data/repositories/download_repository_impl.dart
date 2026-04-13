import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../api/download_station_api.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  const DownloadRepositoryImpl(this._api);

  final DownloadStationApi _api;

  @override
  Future<List<DownloadTask>> listTasks() async {
    final items = await _api.listTasks();

    return items
        .map(
          (item) => DownloadTask(
            id: item.id,
            title: item.title,
            status: item.status,
            progress: item.progress,
          ),
        )
        .toList();
  }

  @override
  Future<List<String>> createTask({
    required List<String> urls,
    String destination = 'Download',
  }) {
    return _api.createTask(urls: urls, destination: destination);
  }

  @override
  Future<void> pauseTask({
    required String id,
  }) {
    return _api.pauseTask(id: id);
  }

  @override
  Future<void> resumeTask({
    required String id,
  }) {
    return _api.resumeTask(id: id);
  }

  @override
  Future<void> deleteTask({
    required String id,
  }) {
    return _api.deleteTask(id: id);
  }
}
