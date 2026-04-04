import 'information_center_api.dart';
import 'upgrade_api.dart';
import '../models/information_center_model.dart';
import '../models/system_status_model.dart';
import '../../domain/entities/upgrade_status.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview();

  Future<InformationCenterModel> fetchInformationCenter({
    required String serverName,
  });
}

class DsmSystemApi implements SystemApi {
  DsmSystemApi({bool ignoreBadCertificate = false});

  final _informationCenterApi = InformationCenterApi();
  final _upgradeApi = UpgradeApi();

  @override
  Future<SystemStatusModel> fetchOverview() {
    throw UnimplementedError('fetchOverview 待实现 - 需要创建 system_info_api.dart');
  }

  @override
  Future<InformationCenterModel> fetchInformationCenter({required String serverName}) {
    return _informationCenterApi.fetchInformationCenter(serverName: serverName);
  }

  Future<UpgradeStatus> checkUpgrade() {
    return _upgradeApi.checkUpgrade();
  }
}
