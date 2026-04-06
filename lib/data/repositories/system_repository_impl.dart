import '../../core/network/app_dio.dart';
import '../../domain/entities/dsm_group.dart';
import '../../domain/entities/dsm_user.dart';
import '../../domain/entities/external_access.dart';
import '../../domain/entities/external_device.dart';
import '../../domain/entities/file_service.dart';
import '../../domain/entities/index_service.dart';
import '../../domain/entities/information_center.dart';
import '../../domain/entities/network.dart';
import '../../domain/entities/power_schedule_task.dart';
import '../../domain/entities/power_status.dart';
import '../../domain/entities/shared_folder.dart';
import '../../domain/entities/system_status.dart';
import '../../domain/entities/task_scheduler.dart';
import '../../domain/entities/terminal_settings.dart';
import '../../domain/entities/upgrade_status.dart';
import '../../domain/repositories/system_repository.dart';
import '../api/system_api.dart';
import '../api/realtime_api.dart';
import '../api/transfer_log_api.dart';
import '../api/shared_folder_api.dart';
import '../api/file_service_api.dart';
import '../api/user_group_api.dart';
import '../api/task_scheduler_api.dart';
import '../api/power_management_api.dart';
import '../api/external_access_api.dart';
import '../api/index_service_api.dart';
import '../api/external_device_api.dart';
import '../api/terminal_api.dart';
import '../api/network_api.dart';
import '../api/upgrade_api.dart';

class SystemRepositoryImpl implements SystemRepository {
  SystemRepositoryImpl(this._systemApi, {
    RealtimeApi? realtimeApi,
    TransferLogApi? transferLogApi,
    SharedFolderApi? sharedFolderApi,
    FileServiceApi? fileServiceApi,
    UserGroupApi? userGroupApi,
    TaskSchedulerApi? taskSchedulerApi,
    PowerManagementApi? powerManagementApi,
    ExternalAccessApi? externalAccessApi,
    IndexServiceApi? indexServiceApi,
    ExternalDeviceApi? externalDeviceApi,
    TerminalApi? terminalApi,
    NetworkApi? networkApi,
    UpgradeApi? upgradeApi,
  })
      : _realtimeApi = realtimeApi ?? DsmRealtimeApi(),
        _transferLogApi = transferLogApi ?? TransferLogApi(),
        _sharedFolderApi = sharedFolderApi ?? SharedFolderApi(),
        _fileServiceApi = fileServiceApi ?? FileServiceApi(),
        _userGroupApi = userGroupApi ?? UserGroupApi(),
        _taskSchedulerApi = taskSchedulerApi ?? TaskSchedulerApi(),
        _powerManagementApi = powerManagementApi ?? PowerManagementApi(),
        _externalAccessApi = externalAccessApi ?? ExternalAccessApi(),
        _indexServiceApi = indexServiceApi ?? IndexServiceApi(),
        _externalDeviceApi = externalDeviceApi ?? ExternalDeviceApi(),
        _terminalApi = terminalApi ?? TerminalApi(),
        _networkApi = networkApi ?? NetworkApi(),
        _upgradeApi = upgradeApi ?? UpgradeApi();

  final SystemApi _systemApi;
  final RealtimeApi _realtimeApi;
  final TransferLogApi _transferLogApi;
  final SharedFolderApi _sharedFolderApi;
  final FileServiceApi _fileServiceApi;
  final UserGroupApi _userGroupApi;
  final TaskSchedulerApi _taskSchedulerApi;
  final PowerManagementApi _powerManagementApi;
  final ExternalAccessApi _externalAccessApi;
  final IndexServiceApi _indexServiceApi;
  final ExternalDeviceApi _externalDeviceApi;
  final TerminalApi _terminalApi;
  final NetworkApi _networkApi;
  final UpgradeApi _upgradeApi;

  @override
  Future<ExternalAccessData> fetchExternalAccess() async {
    final model = await _externalAccessApi.fetchExternalAccess();

    return ExternalAccessData(
      nextUpdateTime: model.nextUpdateTime,
      records: model.records
          .map(
            (item) => DdnsRecord(
              id: item.id,
              provider: item.provider,
              hostname: item.hostname,
              ip: item.ip,
              status: item.status,
              lastUpdated: item.lastUpdated,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> refreshDdns({String? recordId}) {
    return _externalAccessApi.refreshDdns(recordId: recordId);
  }

  @override
  Future<IndexServiceData> fetchIndexService() async {
    final model = await _indexServiceApi.fetchIndexService();

    return IndexServiceData(
      indexing: model.indexing,
      statusText: model.statusText,
      thumbnailQuality: model.thumbnailQuality,
      tasks: model.tasks
          .map(
            (item) => IndexServiceTask(
              id: item.id,
              type: item.type,
              status: item.status,
              detail: item.detail,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> setThumbnailQuality({required int quality}) {
    return _indexServiceApi.setThumbnailQuality(quality: quality);
  }

  @override
  Future<void> rebuildIndex() {
    return _indexServiceApi.rebuildIndex();
  }

  @override
  Future<List<ExternalDevice>> fetchExternalDevices() async {
    final models = await _externalDeviceApi.fetchExternalDevices();
    return models
        .map(
          (item) => ExternalDevice(
            id: item.id,
            name: item.name,
            bus: item.bus,
            vendor: item.vendor,
            model: item.model,
            status: item.status,
            canEject: item.canEject,
            volumes: item.volumes
                .map(
                  (volume) => ExternalDeviceVolume(
                    name: volume.name,
                    fileSystem: volume.fileSystem,
                    mountPath: volume.mountPath,
                    totalSizeText: volume.totalSizeText,
                    usedSizeText: volume.usedSizeText,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Future<void> ejectExternalDevice({required String id, required String bus}) {
    return _externalDeviceApi.ejectExternalDevice(id: id, bus: bus);
  }

  @override
  Future<List<ScheduledTask>> fetchScheduledTasks() async {
    final models = await _taskSchedulerApi.fetchScheduledTasks();
    return models
        .map(
          (item) => ScheduledTask(
            id: item.id,
            name: item.name,
            owner: item.owner,
            type: item.type,
            enabled: item.enabled,
            running: item.running,
            nextTriggerTime: item.nextTriggerTime,
            records: item.records
                .map(
                  (record) => ScheduledTaskRecord(
                    startTime: record.startTime,
                    result: record.result,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Future<void> runScheduledTask({required int id, required String type, required String name}) {
    return _taskSchedulerApi.runScheduledTask(id: id, type: type, name: name);
  }

  @override
  Future<void> setScheduledTaskEnabled({required int id, required bool enabled}) {
    return _taskSchedulerApi.setScheduledTaskEnabled(id: id, enabled: enabled);
  }

  @override
  Future<InformationCenterData> fetchInformationCenter() async {
    final model = await _systemApi.fetchInformationCenter(
      serverName: connectionStore.server?.name ?? '我的 NAS',
    );

    return InformationCenterData(
      serverName: model.serverName,
      serialNumber: model.serialNumber,
      modelName: model.modelName,
      cpuName: model.cpuName,
      cpuCores: model.cpuCores,
      cpuClockSpeedStr: model.cpuClockSpeedStr,
      ramSize: model.ramSize,
      sysTemp: model.sysTemp,
      time: model.time,
      temperatureWarning: model.temperatureWarning,
      memoryBytes: model.memoryBytes,
      dsmVersion: model.dsmVersion,
      systemTime: model.systemTime,
      uptimeText: model.uptimeText,
      thermalStatus: model.thermalStatus,
      timezone: model.timezone,
      dnsServer: model.dnsServer,
      gateway: model.gateway,
      workgroup: model.workgroup,
      externalDevices: model.externalDevices
          .map(
            (item) => InformationCenterExternalDevice(
              name: item.name,
              type: item.type,
              status: item.status,
            ),
          )
          .toList(),
      lanNetworks: model.lanNetworks
          .map(
            (item) => InformationCenterLanNetwork(
              name: item.name,
              macAddress: item.macAddress,
              ipAddress: item.ipAddress,
              subnetMask: item.subnetMask,
            ),
          )
          .toList(),
      disks: model.disks
          .map(
            (item) => InformationCenterDisk(
              name: item.name,
              serialNumber: item.serialNumber,
              capacityBytes: item.capacityBytes,
              temperatureText: item.temperatureText,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<SystemStatus> fetchOverview() async {
    final model = await _systemApi.fetchOverview();

    return SystemStatus(
      serverName: model.serverName,
      dsmVersion: model.dsmVersion,
      cpuUsage: model.cpuUsage,
      cpuUserUsage: model.cpuUserUsage,
      cpuSystemUsage: model.cpuSystemUsage,
      cpuIoWaitUsage: model.cpuIoWaitUsage,
      load1: model.load1,
      load5: model.load5,
      load15: model.load15,
      memoryUsage: model.memoryUsage,
      memoryTotalBytes: model.memoryTotalBytes,
      memoryUsedBytes: model.memoryUsedBytes,
      memoryBufferBytes: model.memoryBufferBytes,
      memoryCachedBytes: model.memoryCachedBytes,
      memoryAvailableBytes: model.memoryAvailableBytes,
      storageUsage: model.storageUsage,
      networkUploadBytesPerSecond: model.networkUploadBytesPerSecond,
      networkDownloadBytesPerSecond: model.networkDownloadBytesPerSecond,
      diskReadBytesPerSecond: model.diskReadBytesPerSecond,
      diskWriteBytesPerSecond: model.diskWriteBytesPerSecond,
      networkInterfaces: model.networkInterfaces
          .map((item) => NetworkInterfaceStatus(name: item.name, uploadBytesPerSecond: item.uploadBytesPerSecond, downloadBytesPerSecond: item.downloadBytesPerSecond))
          .toList(),
      disks: model.disks
          .map((item) => DiskStatus(name: item.name, utilization: item.utilization, readBytesPerSecond: item.readBytesPerSecond, writeBytesPerSecond: item.writeBytesPerSecond, readIops: item.readIops, writeIops: item.writeIops))
          .toList(),
      volumePerformances: model.volumePerformances
          .map((item) => VolumePerformanceStatus(name: item.name, utilization: item.utilization, readBytesPerSecond: item.readBytesPerSecond, writeBytesPerSecond: item.writeBytesPerSecond, readIops: item.readIops, writeIops: item.writeIops))
          .toList(),
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
  Future<List<SharedFolder>> fetchSharedFolders() {
    return _sharedFolderApi.fetchSharedFolders();
  }

  @override
  Future<List<DsmUser>> fetchUsers() async {
    final models = await _userGroupApi.fetchUsers();
    return models
        .map(
          (item) => DsmUser(
            name: item.name,
            description: item.description,
            email: item.email,
            status: item.status,
            isExpired: item.isExpired,
          ),
        )
        .toList();
  }

  @override
  Future<List<DsmGroup>> fetchGroups() async {
    final models = await _userGroupApi.fetchGroups();
    return models
        .map(
          (item) => DsmGroup(
            name: item.name,
            description: item.description,
            memberCount: item.memberCount,
          ),
        )
        .toList();
  }

  @override
  Stream<SystemStatus> watchOverview() {
    return _realtimeApi.watchUtilization().map((model) => SystemStatus(
          serverName: model.serverName,
          dsmVersion: model.dsmVersion,
          cpuUsage: model.cpuUsage,
          cpuUserUsage: model.cpuUserUsage,
          cpuSystemUsage: model.cpuSystemUsage,
          cpuIoWaitUsage: model.cpuIoWaitUsage,
          load1: model.load1,
          load5: model.load5,
          load15: model.load15,
          memoryUsage: model.memoryUsage,
          memoryTotalBytes: model.memoryTotalBytes,
          memoryUsedBytes: model.memoryUsedBytes,
          memoryBufferBytes: model.memoryBufferBytes,
          memoryCachedBytes: model.memoryCachedBytes,
          memoryAvailableBytes: model.memoryAvailableBytes,
          storageUsage: model.storageUsage,
          networkUploadBytesPerSecond: model.networkUploadBytesPerSecond,
          networkDownloadBytesPerSecond: model.networkDownloadBytesPerSecond,
          diskReadBytesPerSecond: model.diskReadBytesPerSecond,
          diskWriteBytesPerSecond: model.diskWriteBytesPerSecond,
          networkInterfaces: model.networkInterfaces
              .map((item) => NetworkInterfaceStatus(
                    name: item.name,
                    uploadBytesPerSecond: item.uploadBytesPerSecond,
                    downloadBytesPerSecond: item.downloadBytesPerSecond,
                  ))
              .toList(),
          disks: model.disks
              .map((item) => DiskStatus(
                    name: item.name,
                    utilization: item.utilization,
                    readBytesPerSecond: item.readBytesPerSecond,
                    writeBytesPerSecond: item.writeBytesPerSecond,
                    readIops: item.readIops,
                    writeIops: item.writeIops,
                  ))
              .toList(),
          volumePerformances: model.volumePerformances
              .map((item) => VolumePerformanceStatus(
                    name: item.name,
                    utilization: item.utilization,
                    readBytesPerSecond: item.readBytesPerSecond,
                    writeBytesPerSecond: item.writeBytesPerSecond,
                    readIops: item.readIops,
                    writeIops: item.writeIops,
                  ))
              .toList(),
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
        ));
  }

  @override
  Future<FileServicesModel> fetchFileServices() {
    return _fileServiceApi.fetchFileServices();
  }

  @override
  Future<void> setFileServiceEnabled({
    required String serviceName,
    required bool enabled,
  }) {
    return _fileServiceApi.setFileServiceEnabled(
      serviceName: serviceName,
      enabled: enabled,
    );
  }

  @override
  Future<NetworkModel> fetchNetwork() {
    return _networkApi.fetchNetwork();
  }

  @override
  Future<UpgradeStatus> checkUpgrade() {
    return _upgradeApi.checkUpgrade();
  }

  @override
  Future<TerminalSettings> fetchTerminalSettings() {
    return _terminalApi.fetchTerminalSettings();
  }

  @override
  Future<void> setTerminalSettings({
    required bool sshEnabled,
    required bool telnetEnabled,
    required int sshPort,
  }) {
    return _terminalApi.setTerminalSettings(
      sshEnabled: sshEnabled,
      telnetEnabled: telnetEnabled,
      sshPort: sshPort,
    );
  }

  @override
  Future<void> shutdown({bool force = false}) {
    return _powerManagementApi.shutdown(force: force);
  }

  @override
  Future<void> reboot({bool force = false}) {
    return _powerManagementApi.reboot(force: force);
  }

  @override
  Future<PowerStatus> fetchPowerStatus() {
    return _powerManagementApi.fetchPowerStatus();
  }

  @override
  Future<void> setPowerSettings({
    int? ledBrightness,
    String? fanSpeedMode,
    bool? poweronBeep,
    bool? poweroffBeep,
  }) {
    return _powerManagementApi.setPowerSettings(
      ledBrightness: ledBrightness,
      fanSpeedMode: fanSpeedMode,
      poweronBeep: poweronBeep,
      poweroffBeep: poweroffBeep,
    );
  }

  @override
  Future<List<PowerScheduleTask>> fetchPowerSchedule() {
    return _powerManagementApi.fetchPowerSchedule();
  }

  @override
  Future<void> updateUser({
    required String name,
    String? description,
    String? email,
    String? password,
  }) {
    return _userGroupApi.updateUser(
      name: name,
      description: description,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> setUserStatus({
    required String name,
    required bool disabled,
  }) {
    return _userGroupApi.setUserStatus(
      name: name,
      disabled: disabled,
    );
  }

  @override
  Future<void> createSharedFolder(SharedFolderEditRequest request) => _sharedFolderApi.createSharedFolder(request);

  @override
  Future<void> updateSharedFolder(SharedFolderEditRequest request) => _sharedFolderApi.updateSharedFolder(request);

  @override
  Future<void> deleteSharedFolder(String name) => _sharedFolderApi.deleteSharedFolder(name);

  @override
  Future<Map<String, bool>> fetchTransferLogStatus() => _transferLogApi.fetchTransferLogStatus();

  @override
  Future<void> setTransferLogStatus({bool? smbEnabled, bool? afpEnabled}) =>
      _transferLogApi.setTransferLogStatus(cifsEnabled: smbEnabled, afpEnabled: afpEnabled);

  @override
  Future<Map<String, bool>> fetchTransferLogLevel(String protocol) => _transferLogApi.fetchTransferLogLevel(protocol);

  @override
  Future<void> setTransferLogLevel(String protocol, Map<String, bool> levels) =>
      _transferLogApi.setTransferLogLevel(protocol, levels);
}
