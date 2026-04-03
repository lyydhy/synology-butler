import '../models/information_center_model.dart';
import '../models/system_status_model.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview();

  Future<InformationCenterModel> fetchInformationCenter({
    required String serverName,
  });
}

// TODO: 实现 DsmSystemApi - 需要恢复 fetchOverview 和 fetchInformationCenter 方法及其辅助方法
class DsmSystemApi implements SystemApi {
  DsmSystemApi({bool ignoreBadCertificate = false});

  @override
  Future<SystemStatusModel> fetchOverview() {
    throw UnimplementedError('fetchOverview 待实现 - 需要创建 system_info_api.dart');
  }

  @override
  Future<InformationCenterModel> fetchInformationCenter({required String serverName}) {
    throw UnimplementedError('fetchInformationCenter 待实现 - 需要创建 information_center_api.dart');
  }
}
