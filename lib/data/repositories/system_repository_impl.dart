import '../../core/network/app_dio.dart';
import '../../domain/entities/information_center.dart';
import '../../domain/entities/system_status.dart';
import '../../domain/repositories/system_repository.dart';
import '../api/system_api.dart';

class SystemRepositoryImpl implements SystemRepository {
  const SystemRepositoryImpl(this._systemApi);

  final SystemApi _systemApi;

  @override
  Future<InformationCenterData> fetchInformationCenter() async {
    final model = await _systemApi.fetchInformationCenter(
      serverName: AppDioFactory.connectionStore.server?.name ?? '我的 NAS',
    );

    return InformationCenterData(
      serverName: model.serverName,
      serialNumber: model.serialNumber,
      modelName: model.modelName,
      cpuName: model.cpuName,
      cpuCores: model.cpuCores,
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
  Stream<SystemStatus> watchOverview() {
    final synoToken = AppDioFactory.connectionStore.session?.synoToken;
    if (synoToken == null || synoToken.isEmpty) {
      throw Exception('Missing SynoToken for realtime utilization');
    }

    return _systemApi.watchUtilization().map(
      (model) => SystemStatus(
        serverName: AppDioFactory.connectionStore.server?.name ?? '我的 NAS',
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
}
