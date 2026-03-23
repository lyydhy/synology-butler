import '../../core/utils/server_url_helper.dart';
import '../../domain/entities/download_task.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/repositories/download_repository.dart';
import '../api/download_station_api.dart';

class DownloadRepositoryImpl implements DownloadRepository {
  const DownloadRepositoryImpl(this._api);

  final DownloadStationApi _api;

  @override
  Future<List<DownloadTask>> listTasks({
    required NasServer server,
    required NasSession session,
  }) async {
    final items = await _api.listTasks(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
    );

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
    required NasServer server,
    required NasSession session,
    required String uri,
  }) {
    return _api.createTask(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      uri: uri,
    );
  }

  @override
  Future<void> pauseTask({
    required NasServer server,
    required NasSession session,
    required String id,
  }) {
    return _api.pauseTask(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      id: id,
    );
  }

  @override
  Future<void> resumeTask({
    required NasServer server,
    required NasSession session,
    required String id,
  }) {
    return _api.resumeTask(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      id: id,
    );
  }

  @override
  Future<void> deleteTask({
    required NasServer server,
    required NasSession session,
    required String id,
  }) {
    return _api.deleteTask(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      id: id,
    );
  }
}
