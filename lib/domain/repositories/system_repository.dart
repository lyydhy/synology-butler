import '../entities/external_access.dart';
import '../entities/index_service.dart';
import '../entities/information_center.dart';
import '../entities/system_status.dart';

abstract class SystemRepository {
  Future<SystemStatus> fetchOverview();

  Stream<SystemStatus> watchOverview();

  Future<InformationCenterData> fetchInformationCenter();

  Future<ExternalAccessData> fetchExternalAccess();

  Future<void> refreshDdns({String? recordId});

  Future<IndexServiceData> fetchIndexService();

  Future<void> setThumbnailQuality({required int quality});

  Future<void> rebuildIndex();
}
