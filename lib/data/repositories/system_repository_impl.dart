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
    );

    return SystemStatus(
      serverName: model.serverName,
      dsmVersion: model.dsmVersion,
      cpuUsage: model.cpuUsage,
      memoryUsage: model.memoryUsage,
      storageUsage: model.storageUsage,
      modelName: model.modelName,
      serialNumber: model.serialNumber,
      uptimeText: model.uptimeText,
    );
  }
}
