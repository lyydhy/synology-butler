import '../entities/dsm_group.dart';
import '../entities/dsm_user.dart';
import '../entities/external_access.dart';
import '../entities/external_device.dart';
import '../entities/file_service.dart';
import '../entities/index_service.dart';
import '../entities/information_center.dart';
import '../entities/network.dart';
import '../entities/power_schedule_task.dart';
import '../entities/power_status.dart';
import '../entities/shared_folder.dart';
import '../entities/system_status.dart';
import '../entities/task_scheduler.dart';
import '../entities/terminal_settings.dart';
import '../entities/upgrade_status.dart';

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

  /// 创建共享文件夹
  Future<void> createSharedFolder(SharedFolderEditRequest request);

  /// 编辑共享文件夹
  Future<void> updateSharedFolder(SharedFolderEditRequest request);

  /// 删除共享文件夹
  Future<void> deleteSharedFolder(String name);

  Future<List<DsmUser>> fetchUsers();

  Future<List<DsmGroup>> fetchGroups();

  Future<FileServicesModel> fetchFileServices();

  /// 设置文件服务启用状态
  Future<void> setFileServiceEnabled({
    required String serviceName,
    required bool enabled,
  });

  /// 获取文件传输日志状态
  Future<Map<String, bool>> fetchTransferLogStatus();

  /// 设置文件传输日志状态
  Future<void> setTransferLogStatus({
    bool? smbEnabled,
    bool? afpEnabled,
  });

  /// 获取传输日志级别设置
  /// [protocol] 协议名称: cifs, afp
  Future<Map<String, bool>> fetchTransferLogLevel(String protocol);

  /// 设置传输日志级别
  /// [protocol] 协议名称: cifs, afp
  /// [levels] 日志级别: create, write, move, delete, read, rename
  Future<void> setTransferLogLevel(String protocol, Map<String, bool> levels);

  Future<NetworkModel> fetchNetwork();

  Future<UpgradeStatus> checkUpgrade();

  Future<TerminalSettings> fetchTerminalSettings();

  Future<void> setTerminalSettings({
    required bool sshEnabled,
    required bool telnetEnabled,
    required int sshPort,
  });

  /// 关机
  Future<void> shutdown({bool force = false});

  /// 重启
  Future<void> reboot({bool force = false});

  /// 获取电源状态
  Future<PowerStatus> fetchPowerStatus();

  /// 设置电源选项
  Future<void> setPowerSettings({
    int? ledBrightness,
    String? fanSpeedMode,
    bool? poweronBeep,
    bool? poweroffBeep,
  });

  /// 获取开关机计划
  Future<List<PowerScheduleTask>> fetchPowerSchedule();

  /// 更新用户信息
  Future<void> updateUser({
    required String name,
    String? description,
    String? email,
    String? password,
  });

  /// 设置用户状态（启用/禁用）
  Future<void> setUserStatus({
    required String name,
    required bool disabled,
  });
}
