import '../entities/dsm_group.dart';
import '../entities/dsm_user.dart';
import '../entities/external_access.dart';
import '../entities/external_device.dart';
import '../entities/file_service.dart';
import '../entities/index_service.dart';
import '../entities/information_center.dart';
import '../entities/network.dart';
import '../entities/shared_folder.dart';
import '../entities/system_status.dart';
import '../entities/task_scheduler.dart';

abstract class SystemRepository {
  Future<SystemStatus> fetchOverview();

  Stream<SystemStatus> watchOverview();

  Future<InformationCenterData> fetchInformationCenter();

  Future<ExternalAccessData> fetchExternalAccess();

  Future<void> refreshDdns({String? recordId});

  Future<IndexServiceData> fetchIndexService();

  Future<void> setThumbnailQuality({required int quality});

  Future<void> rebuildIndex();

  Future<List<ScheduledTask>> fetchScheduledTasks();

  Future<void> runScheduledTask({required int id, required String type, required String name});

  Future<void> setScheduledTaskEnabled({required int id, required bool enabled});

  Future<List<ExternalDevice>> fetchExternalDevices();

  Future<void> ejectExternalDevice({required String id, required String bus});

  Future<List<SharedFolder>> fetchSharedFolders();

  Future<List<DsmUser>> fetchUsers();

  Future<List<DsmGroup>> fetchGroups();

  Future<FileServicesModel> fetchFileServices();

  Future<NetworkModel> fetchNetwork();
}
