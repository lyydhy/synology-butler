import '../entities/information_center.dart';
import '../entities/system_status.dart';

abstract class SystemRepository {
  Future<SystemStatus> fetchOverview();

  Stream<SystemStatus> watchOverview();

  Future<InformationCenterData> fetchInformationCenter();
}
