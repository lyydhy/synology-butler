import '../../core/network/business_connection_context.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/repositories/download_repository.dart';
import '../api/download_station_api.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  const DownloadRepositoryImpl(this._api, this._context);

  final DownloadStationApi _api;
  final BusinessConnectionContext _context;

  @override
  Future<List<DownloadTask>> listTasks() async {
    final items = await _api.listTasks(context: _context);

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
  Future<void> createTask({
    required String uri,
  }) {
    return _api.createTask(
      context: _context,
      uri: uri,
    );
  }

  @override
  Future<void> pauseTask({
    required String id,
  }) {
    return _api.pauseTask(
      context: _context,
      id: id,
    );
  }

  @override
  Future<void> resumeTask({
    required String id,
  }) {
    return _api.resumeTask(
      context: _context,
      id: id,
    );
  }

  @override
  Future<void> deleteTask({
    required String id,
  }) {
    return _api.deleteTask(
      context: _context,
      id: id,
    );
  }
}
