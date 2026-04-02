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

class SystemRepositoryImpl implements SystemRepository {
  const SystemRepositoryImpl(this._systemApi);

  final SystemApi _systemApi;

  @override
  Future<ExternalAccessData> fetchExternalAccess() async {
    final model = await _systemApi.fetchExternalAccess();

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
    return _systemApi.refreshDdns(recordId: recordId);
  }

  @override
  Future<IndexServiceData> fetchIndexService() async {
    final model = await _systemApi.fetchIndexService();

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
    return _systemApi.setThumbnailQuality(quality: quality);
  }

  @override
  Future<void> rebuildIndex() {
    return _systemApi.rebuildIndex();
  }

  @override
  Future<List<ExternalDevice>> fetchExternalDevices() async {
    final models = await _systemApi.fetchExternalDevices();
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
    return _systemApi.ejectExternalDevice(id: id, bus: bus);
  }

  @override
  Future<List<ScheduledTask>> fetchScheduledTasks() async {
    final models = await _systemApi.fetchScheduledTasks();
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
    return _systemApi.runScheduledTask(id: id, type: type, name: name);
  }

  @override
  Future<void> setScheduledTaskEnabled({required int id, required bool enabled}) {
    return _systemApi.setScheduledTaskEnabled(id: id, enabled: enabled);
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
  Future<List<SharedFolder>> fetchSharedFolders() async {
    final models = await _systemApi.fetchSharedFolders();
    return models
        .map(
          (item) => SharedFolder(
            name: item.name,
            description: item.description,
            volumePath: item.volumePath,
            fileSystem: item.fileSystem,
            isReadOnly: item.isReadOnly,
            isHidden: item.isHidden,
            recycleBinEnabled: item.recycleBinEnabled,
            encrypted: item.encrypted,
            usageText: item.usageText,
          ),
        )
        .toList();
  }

  @override
  Future<List<DsmUser>> fetchUsers() async {
    final models = await _systemApi.fetchUsers();
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
    final models = await _systemApi.fetchGroups();
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
    final synoToken = connectionStore.session?.synoToken;
    if (synoToken == null || synoToken.isEmpty) {
      throw Exception('Missing SynoToken for realtime utilization');
    }

    return _systemApi.watchUtilization().map(
      (model) => SystemStatus(
        serverName: connectionStore.server?.name ?? '我的 NAS',
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
      ),
    );
  }

  @override
  Future<FileServicesModel> fetchFileServices() {
    return _systemApi.fetchFileServices();
  }

  @override
  Future<void> setFileServiceEnabled({
    required String serviceName,
    required bool enabled,
  }) {
    return _systemApi.setFileServiceEnabled(
      serviceName: serviceName,
      enabled: enabled,
    );
  }

  @override
  Future<NetworkModel> fetchNetwork() {
    return _systemApi.fetchNetwork();
  }

  @override
  Future<UpgradeStatus> checkUpgrade() {
    return _systemApi.checkUpgrade();
  }

  @override
  Future<TerminalSettings> fetchTerminalSettings() {
    return _systemApi.fetchTerminalSettings();
  }

  @override
  Future<void> setTerminalSettings({
    required bool sshEnabled,
    required bool telnetEnabled,
    required int sshPort,
  }) {
    return _systemApi.setTerminalSettings(
      sshEnabled: sshEnabled,
      telnetEnabled: telnetEnabled,
      sshPort: sshPort,
    );
  }

  @override
  Future<void> shutdown({bool force = false}) {
    return _systemApi.shutdown(force: force);
  }

  @override
  Future<void> reboot({bool force = false}) {
    return _systemApi.reboot(force: force);
  }

  @override
  Future<PowerStatus> fetchPowerStatus() {
    return _systemApi.fetchPowerStatus();
  }

  @override
  Future<void> setPowerSettings({
    int? ledBrightness,
    String? fanSpeedMode,
    bool? poweronBeep,
    bool? poweroffBeep,
  }) {
    return _systemApi.setPowerSettings(
      ledBrightness: ledBrightness,
      fanSpeedMode: fanSpeedMode,
      poweronBeep: poweronBeep,
      poweroffBeep: poweroffBeep,
    );
  }

  @override
  Future<List<PowerScheduleTask>> fetchPowerSchedule() {
    return _systemApi.fetchPowerSchedule();
  }

  @override
  Future<void> updateUser({
    required String name,
    String? description,
    String? email,
    String? password,
  }) {
    return _systemApi.updateUser(
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
    return _systemApi.setUserStatus(
      name: name,
      disabled: disabled,
    );
  }
}
