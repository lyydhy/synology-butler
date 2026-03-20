import '../../core/utils/server_url_helper.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/entities/system_status.dart';
import '../../domain/repositories/system_repository.dart';
import '../api/system_api.dart';

class SystemRepositoryImpl implements SystemRepository {
  const SystemRepositoryImpl(this._systemApi);

  final SystemApi _systemApi;

  @override
  Future<SystemStatus> fetchOverview({
    required NasServer server,
    required NasSession session,
  }) async {
    final model = await _systemApi.fetchOverview(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      synoToken: session.synoToken,
    );

    return SystemStatus(
      serverName: model.serverName,
      dsmVersion: model.dsmVersion,
      cpuUsage: model.cpuUsage,
      memoryUsage: model.memoryUsage,
      storageUsage: model.storageUsage,
      volumes: model.volumes
          .map(
            (item) => StorageVolumeStatus(
              name: item.name,
              usage: item.usage,
              usedBytes: item.usedBytes,
              totalBytes: item.totalBytes,
            ),
          )
          .toList(),
      modelName: model.modelName,
      serialNumber: model.serialNumber,
      uptimeText: model.uptimeText,
    );
  }

  @override
  Stream<SystemStatus> watchOverview({
    required NasServer server,
    required NasSession session,
  }) {
    final synoToken = session.synoToken;
    if (synoToken == null || synoToken.isEmpty) {
      throw Exception('Missing SynoToken for realtime utilization');
    }

    return _systemApi.watchUtilization(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      synoToken: synoToken,
      cookieHeader: session.cookieHeader,
    ).map(
      (model) => SystemStatus(
        serverName: server.name,
        dsmVersion: model.dsmVersion,
        cpuUsage: model.cpuUsage,
        memoryUsage: model.memoryUsage,
        storageUsage: model.storageUsage,
        volumes: model.volumes
            .map(
              (item) => StorageVolumeStatus(
                name: item.name,
                usage: item.usage,
                usedBytes: item.usedBytes,
                totalBytes: item.totalBytes,
              ),
            )
            .toList(),
        modelName: model.modelName,
        serialNumber: model.serialNumber,
        uptimeText: model.uptimeText,
      ),
    );
  }
}
