import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/file_service.dart';
import '../../domain/entities/network.dart';
import '../../domain/entities/terminal_settings.dart';
import '../../domain/entities/upgrade_status.dart';
import '../models/dsm_group_model.dart';
import '../models/dsm_user_model.dart';
import '../models/external_access_model.dart';
import '../models/external_device_model.dart';
import '../models/file_service_model.dart';
import '../models/index_service_model.dart';
import '../models/information_center_model.dart';
import '../models/shared_folder_model.dart';
import '../models/system_status_model.dart';
import '../models/task_scheduler_model.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview();

  Stream<SystemStatusModel> watchUtilization();

  Future<InformationCenterModel> fetchInformationCenter({
    required String serverName,
  });

  Future<ExternalAccessModel> fetchExternalAccess();

  Future<void> refreshDdns({String? recordId});

  Future<IndexServiceModel> fetchIndexService();

  Future<void> setThumbnailQuality({required int quality});

  Future<void> rebuildIndex();

  Future<List<ScheduledTaskModel>> fetchScheduledTasks();

  Future<void> runScheduledTask({required int id, required String type, required String name});

  Future<void> setScheduledTaskEnabled({required int id, required bool enabled});

  Future<List<ExternalDeviceModel>> fetchExternalDevices();

  Future<void> ejectExternalDevice({required String id, required String bus});

  Future<List<SharedFolderModel>> fetchSharedFolders();

  Future<List<DsmUserModel>> fetchUsers();

  Future<List<DsmGroupModel>> fetchGroups();

  /// 获取文件服务状态（SMB、NFS、FTP、AFP、SFTP）
  Future<FileServicesModel> fetchFileServices();

  /// 获取网络状态（常规、接口、代理、网关）
  Future<NetworkModel> fetchNetwork();

  /// 检查 DSM 更新
  Future<UpgradeStatus> checkUpgrade();

  /// 获取终端设置（SSH/Telnet）
  Future<TerminalSettings> fetchTerminalSettings();

  /// 设置终端（SSH/Telnet）
  Future<void> setTerminalSettings({
    required bool sshEnabled,
    required bool telnetEnabled,
    required int sshPort,
  });
}

class DsmSystemApi implements SystemApi {
  DsmSystemApi({bool ignoreBadCertificate = false})
      : _ignoreBadCertificate = ignoreBadCertificate;

  final bool _ignoreBadCertificate;

  Dio get _dio {
    final server = connectionStore.server;
    return businessDio(
        ignoreBadCertificate:
            server?.ignoreBadCertificate ?? _ignoreBadCertificate);
  }

  String get _baseUrl {
    final server = connectionStore.server;
    if (server == null) return '';
    final scheme = server.https ? 'https' : 'http';
    final host = server.host
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
    final basePath =
        (server.basePath == null || server.basePath!.trim().isEmpty)
            ? ''
            : (server.basePath!.startsWith('/')
                ? server.basePath!
                : '/${server.basePath!}');
    return '$scheme://$host:${server.port}$basePath';
  }

  String get _sid => connectionStore.session?.sid ?? '';

  String? get _synoToken => connectionStore.session?.synoToken;

  String? get _cookieHeader => connectionStore.session?.cookieHeader;

  @override
  Future<ExternalAccessModel> fetchExternalAccess() async {
    final client = _dio;

    Future<Map> postEntry(Map<String, dynamic> data) async {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map? ?? const {};
      }
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载外部访问失败' : '加载外部访问失败');
    }

    final compound = await postEntry({
      'api': 'SYNO.Entry.Request',
      'method': 'request',
      'version': '1',
      'stop_when_error': 'false',
      'mode': 'sequential',
      'compound': jsonEncode([
        {
          'api': 'SYNO.Core.DDNS.Record',
          'method': 'list',
          'version': 1,
        },
      ]),
    });

    final recordData = _extractCompoundApiData(compound, 'SYNO.Core.DDNS.Record');
    final records = ((recordData['records'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => DdnsRecordModel(
            id: (item['id'] ?? '').toString(),
            provider: (item['provider'] ?? '').toString().replaceAll('USER_', '*'),
            hostname: (item['hostname'] ?? '').toString(),
            ip: (item['ip'] ?? '').toString(),
            status: (item['status'] ?? '').toString(),
            lastUpdated: (item['lastupdated'] ?? '').toString(),
          ),
        )
        .toList();

    return ExternalAccessModel(
      records: records,
      nextUpdateTime: recordData['next_update_time']?.toString(),
    );
  }

  @override
  Future<void> refreshDdns({String? recordId}) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.DDNS.Record',
        'method': 'update',
        'version': '1',
        if (recordId != null && recordId.isNotEmpty) 'id': recordId,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '刷新 DDNS 失败' : '刷新 DDNS 失败');
    }
  }

  @override
  Future<IndexServiceModel> fetchIndexService() async {
    final client = _dio;

    Future<Map> postEntry(Map<String, dynamic> data) async {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map? ?? const {};
      }
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载索引服务失败' : '加载索引服务失败');
    }

    final compound = await postEntry({
      'api': 'SYNO.Entry.Request',
      'method': 'request',
      'version': '1',
      'stop_when_error': 'false',
      'mode': 'sequential',
      'compound': jsonEncode([
        {
          'api': 'SYNO.Foto.Index',
          'method': 'get',
          'version': 1,
        },
        {
          'api': 'SYNO.Foto.Thumbnail',
          'method': 'get',
          'version': 1,
        },
        {
          'api': 'SYNO.Foto.Index.Task',
          'method': 'list',
          'version': 1,
        },
      ]),
    });

    final indexData = _extractCompoundApiData(compound, 'SYNO.Foto.Index');
    final thumbnailData = _extractCompoundApiData(compound, 'SYNO.Foto.Thumbnail');
    final taskData = _extractCompoundApiData(compound, 'SYNO.Foto.Index.Task');
    final tasks = ((taskData['tasks'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => IndexServiceTaskModel(
            id: (item['id'] ?? '').toString(),
            type: (item['type'] ?? item['action'] ?? '').toString(),
            status: (item['status'] ?? '').toString(),
            detail: (item['detail'] ?? item['path'])?.toString(),
          ),
        )
        .toList();

    final indexing = indexData['running'] == true || indexData['indexing'] == true;
    final statusText = (indexData['status_text'] ?? indexData['status'] ?? (indexing ? '索引进行中' : '空闲')).toString();
    final thumbnailQuality = int.tryParse((thumbnailData['quality'] ?? thumbnailData['thumb_quality'] ?? 2).toString()) ?? 2;

    return IndexServiceModel(
      indexing: indexing,
      statusText: statusText,
      thumbnailQuality: thumbnailQuality,
      tasks: tasks,
    );
  }

  @override
  Future<void> setThumbnailQuality({required int quality}) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Foto.Thumbnail',
        'method': 'set',
        'version': '1',
        'quality': quality.toString(),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '设置缩图质量失败' : '设置缩图质量失败');
    }
  }

  @override
  Future<void> rebuildIndex() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Foto.Index',
        'method': 'reindex',
        'version': '1',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '重建索引失败' : '重建索引失败');
    }
  }

  @override
  Future<List<ExternalDeviceModel>> fetchExternalDevices() async {
    final client = _dio;

    Future<Map> postEntry(Map<String, dynamic> data) async {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map? ?? const {};
      }
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载外接设备失败' : '加载外接设备失败');
    }

    final compound = await postEntry({
      'api': 'SYNO.Entry.Request',
      'method': 'request',
      'version': '1',
      'stop_when_error': 'false',
      'mode': 'sequential',
      'compound': jsonEncode([
        {
          'api': 'SYNO.Core.ExternalDevice.Storage.USB',
          'method': 'list',
          'version': 1,
          'additional': ['all'],
        },
        {
          'api': 'SYNO.Core.ExternalDevice.Storage.eSATA',
          'method': 'list',
          'version': 1,
          'additional': ['all'],
        },
      ]),
    });

    List<ExternalDeviceModel> parseDevices(Map data, String bus) {
      final devices = ((data['devices'] as List?) ?? (data['disk'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) {
            final volumes = ((item['partitions'] as List?) ?? (item['volumes'] as List?) ?? const [])
                .whereType<Map>()
                .map(
                  (volume) => ExternalDeviceVolumeModel(
                    name: (volume['name'] ?? volume['partition_name'] ?? '').toString(),
                    fileSystem: (volume['fs_type'] ?? volume['file_system'] ?? '').toString(),
                    mountPath: (volume['mount_path'] ?? volume['path'] ?? '').toString(),
                    totalSizeText: (volume['total_size'] ?? volume['total_size_str'] ?? volume['size'] ?? '').toString(),
                    usedSizeText: (volume['used_size'] ?? volume['used_size_str'] ?? '').toString(),
                  ),
                )
                .toList();

            return ExternalDeviceModel(
              id: (item['dev_id'] ?? item['id'] ?? '').toString(),
              name: (item['display_name'] ?? item['name'] ?? item['device_name'] ?? '').toString(),
              bus: bus,
              vendor: (item['vendor'] ?? '').toString(),
              model: (item['model'] ?? '').toString(),
              status: (item['status'] ?? item['device_status'] ?? '').toString(),
              canEject: item['is_busy'] != true,
              volumes: volumes,
            );
          })
          .where((item) => item.id.isNotEmpty || item.name.isNotEmpty)
          .toList();
      return devices;
    }

    final usbData = _extractCompoundApiData(compound, 'SYNO.Core.ExternalDevice.Storage.USB');
    final esataData = _extractCompoundApiData(compound, 'SYNO.Core.ExternalDevice.Storage.eSATA');

    return [
      ...parseDevices(usbData, 'usb'),
      ...parseDevices(esataData, 'esata'),
    ];
  }

  @override
  Future<void> ejectExternalDevice({required String id, required String bus}) async {
    final client = _dio;
    final api = bus == 'esata' ? 'SYNO.Core.ExternalDevice.Storage.eSATA' : 'SYNO.Core.ExternalDevice.Storage.USB';
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': api,
        'method': 'eject',
        'version': '1',
        'dev_id': id,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '弹出外接设备失败' : '弹出外接设备失败');
    }
  }

  @override
  Future<List<SharedFolderModel>> fetchSharedFolders() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Share',
        'method': 'list',
        'version': '1',
        'shareType': 'all',
        'additional': jsonEncode([
          'hidden',
          'recyclebin',
          'encryption',
          'volume_status',
          'usage',
        ]),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载共享文件夹失败' : '加载共享文件夹失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final shares = ((data['shares'] as List?) ?? (data['list'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => SharedFolderModel(
            name: (item['name'] ?? '').toString(),
            description: (item['desc'] ?? item['description'] ?? '').toString(),
            volumePath: (item['vol_path'] ?? item['volume_path'] ?? '').toString(),
            fileSystem: (item['fstype'] ?? item['file_system'] ?? '').toString(),
            isReadOnly: item['readonly'] == true || item['is_read_only'] == true,
            isHidden: item['hidden'] == true,
            recycleBinEnabled: item['enable_recycle_bin'] == true || item['recyclebin'] == true,
            encrypted: item['encryption'] == true || item['is_encrypted'] == true,
            usageText: (item['usage_str'] ?? item['used'] ?? item['usage'] ?? '').toString(),
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();

    return shares;
  }

  @override
  Future<List<DsmUserModel>> fetchUsers() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.User',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'additional': jsonEncode(['email', 'description', 'expired']),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载用户列表失败' : '加载用户列表失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final users = ((data['users'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => DsmUserModel(
            name: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            email: (item['email'] ?? '').toString(),
            status: (item['expired'] ?? 'normal').toString(),
            isExpired: item['expired'] != 'normal' && item['expired'] != null,
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();

    return users;
  }

  @override
  Future<List<DsmGroupModel>> fetchGroups() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Group',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'name_only': 'false',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载群组列表失败' : '加载群组列表失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final groups = ((data['groups'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => DsmGroupModel(
            name: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            memberCount: (item['members'] as List?)?.length ?? 0,
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();

    return groups;
  }

  @override
  Future<List<ScheduledTaskModel>> fetchScheduledTasks() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.TaskScheduler',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'sort_by': 'next_trigger_time',
        'sort_direction': 'DESC',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载任务计划失败' : '加载任务计划失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final tasks = ((data['tasks'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => ScheduledTaskModel(
            id: (item['id'] as num?)?.toInt() ?? 0,
            name: (item['name'] ?? '').toString(),
            owner: (item['owner'] ?? item['real_owner'] ?? '').toString(),
            type: (item['type'] ?? '').toString(),
            enabled: item['enable'] == true,
            running: item['running'] == true,
            nextTriggerTime: (item['next_trigger_time'] ?? '').toString(),
            records: const [],
          ),
        )
        .toList();

    return tasks;
  }

  @override
  Future<void> runScheduledTask({required int id, required String type, required String name}) async {
    final client = _dio;
    final payload = type == 'event_script'
        ? {
            'api': 'SYNO.Core.EventScheduler',
            'method': 'run',
            'version': '1',
            'task_name': jsonEncode([name]),
          }
        : {
            'api': 'SYNO.Core.TaskScheduler',
            'method': 'run',
            'version': '1',
            'task': jsonEncode([id]),
          };
    final response = await client.post(
      '/webapi/entry.cgi',
      data: payload,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '执行任务计划失败' : '执行任务计划失败');
    }
  }

  @override
  Future<void> setScheduledTaskEnabled({required int id, required bool enabled}) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.TaskScheduler',
        'method': 'set_enable',
        'version': '1',
        'status': jsonEncode([
          {
            'id': id,
            'enable': enabled,
          }
        ]),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '更新任务状态失败' : '更新任务状态失败');
    }
  }

  @override
  Future<InformationCenterModel> fetchInformationCenter({
    required String serverName,
  }) async {
    final client = _dio;

    Future<Map> postEntry(Map<String, dynamic> data) async {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map? ?? const {};
      }
      return const {};
    }

    DsmLogger.request(
      module: 'System',
      action: 'fetchInformationCenter',
      method: 'POST',
      path: _baseUrl,
      sid: _sid,
      synoToken: _synoToken,
      cookieHeader: _cookieHeader,
      extra: {
        'apis': [
          'SYNO.Core.System.info',
          'SYNO.Core.System.Utilization.get',
          'SYNO.Core.System.SystemHealth.get',
          'SYNO.Core.System.Time.get',
          'SYNO.Core.Network.get',
          'SYNO.Core.ExternalDevice.Storage.eSATA.get',
          'SYNO.Core.Storage.Disk.list',
        ],
      },
    );

    try {
      final infoData = await postEntry({
        'api': 'SYNO.Core.System',
        'method': 'info',
        'version': '1',
      });
      final utilizationData = await postEntry({
        'api': 'SYNO.Core.System.Utilization',
        'method': 'get',
        'version': '1',
        'type': 'current',
      });
      final systemHealthData = await postEntry({
        'api': 'SYNO.Core.System.SystemHealth',
        'method': 'get',
        'version': '1',
      });
      final timeData = await postEntry({
        'api': 'SYNO.Core.System.Time',
        'method': 'get',
        'version': '1',
      });
      final networkCompoundData = await postEntry({
        'api': 'SYNO.Entry.Request',
        'method': 'request',
        'version': '1',
        'stop_when_error': 'false',
        'mode': 'sequential',
        'compound': jsonEncode([
          {
            'api': 'SYNO.Core.Network',
            'method': 'get',
            'version': 2,
          },
          {
            'api': 'SYNO.Core.Network.Ethernet',
            'method': 'list',
            'version': 2,
          },
          {
            'api': 'SYNO.Core.Network.PPPoE',
            'method': 'list',
            'version': 1,
          },
          {
            'api': 'SYNO.Core.Network.Router.Gateway.List',
            'method': 'get',
            'version': 1,
            'iptype': 'ipv4',
            'type': 'wan',
          },
        ]),
      });
      final externalDeviceCompoundData = await postEntry({
        'api': 'SYNO.Entry.Request',
        'method': 'request',
        'version': '1',
        'mode': 'sequential',
        'compound': jsonEncode([
          {
            'api': 'SYNO.Core.ExternalDevice.Storage.USB',
            'method': 'list',
            'version': 1,
            'additional': ['all'],
          },
          {
            'api': 'SYNO.Core.ExternalDevice.Storage.eSATA',
            'method': 'list',
            'version': 1,
            'additional': ['all'],
          },
        ]),
      });
      final diskData = await postEntry({
        'api': 'SYNO.Core.Storage.Disk',
        'method': 'list',
        'version': '1',
        'additional': jsonEncode(['size_total', 'temp', 'serial']),
      });

      final memory = utilizationData['memory'] as Map? ?? const {};
      final networkData =
          _extractCompoundApiData(networkCompoundData, 'SYNO.Core.Network');
      final ethernetData = _extractCompoundApiData(
          networkCompoundData, 'SYNO.Core.Network.Ethernet');
      final gatewayListData = _extractCompoundApiData(
          networkCompoundData, 'SYNO.Core.Network.Router.Gateway.List');
      final usbData = _extractCompoundApiData(
          externalDeviceCompoundData, 'SYNO.Core.ExternalDevice.Storage.USB');
      final esataData = _extractCompoundApiData(
          externalDeviceCompoundData, 'SYNO.Core.ExternalDevice.Storage.eSATA');
      final networks =
          _extractLanNetworks(networkData, ethernetData, gatewayListData);
      final externalDevices = _extractExternalDevices(usbData, esataData);
      final disks = _extractDisks(diskData);
      final versionText = _buildVersionText(infoData);

      int cpuCores = int.tryParse(infoData['cpu_cores']) ?? 0;
      double cpuClockSpeed = (_toInt(infoData['cpu_clock_speed']) ?? 0) / 1000;
      String cpuClockSpeedStr = (cpuClockSpeed / 1000).toStringAsFixed(2);
      final model = InformationCenterModel(
          serverName:
              (infoData['hostname'] ?? infoData['server_name'] ?? serverName)
                  .toString(),
          serialNumber:
              (infoData['serial'] ?? infoData['serial_number'])?.toString(),
          modelName: (infoData['model'] ?? infoData['modelname'])?.toString(),
          cpuName:
              "${infoData['cpu_vendor']} ${infoData['cpu_family']} ${infoData['cpu_series']}",
          cpuCores: cpuCores,
          cpuClockSpeedStr: "$cpuCores核 @ ${cpuClockSpeedStr}GHz",
          ramSize: _toInt(infoData['ram_size']),
          memoryBytes: _toDouble(infoData['physical_memory'] ??
              memory['real_total'] ??
              memory['avail_real']),
          dsmVersion: versionText,
          systemTime: _resolveSystemTime(timeData),
          uptimeText: systemHealthData['uptime']?.toString() ??
              _formatUptime(infoData['uptime'] ?? infoData['uptime_seconds']),
          thermalStatus: _resolveThermalStatus(systemHealthData),
          timezone: infoData['time_zone_desc'],
          dnsServer: _resolveDns(networkData),
          gateway: _resolveGateway(networkData, gatewayListData),
          workgroup: _resolveWorkgroup(networkData),
          externalDevices: externalDevices,
          lanNetworks: networks,
          disks: disks,
          sysTemp: _toInt(infoData['sys_temp']),
          time: infoData['time'],
          temperatureWarning: infoData['temperature_warning']
      );

      DsmLogger.success(
        module: 'System',
        action: 'fetchInformationCenter',
        path: _baseUrl,
        response: {
          'serverName': model.serverName,
          'lanCount': model.lanNetworks.length,
          'diskCount': model.disks.length,
          'externalDeviceCount': model.externalDevices.length,
        },
      );

      return model;
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchInformationCenter',
        path: _baseUrl,
        reason: e.toString(),
        sid: _sid,
        synoToken: _synoToken,
        cookieHeader: _cookieHeader,
      );
      rethrow;
    }
  }

  @override
  Future<SystemStatusModel> fetchOverview() async {
    final client = _dio;

    DsmLogger.request(
      module: 'System',
      action: 'fetchOverview',
      method: 'GET',
      path: _baseUrl,
      sid: _sid,
      synoToken: _synoToken,
      cookieHeader: _cookieHeader,
      extra: {
        'apis': [
          'SYNO.Core.System',
          'SYNO.Core.System.Utilization',
          'SYNO.Entry.Request/SYNO.Core.Upgrade.Server.check',
          'SYNO.Core.System.SystemHealth',
        ],
      },
    );

    try {
      final infoResponse = await client.get(
        '/webapi/entry.cgi',
        queryParameters: {
          'api': 'SYNO.Core.System',
          'method': 'info',
          'version': '1',
        },
      );

      final utilizationResponse = await client.get(
        '/webapi/entry.cgi',
        queryParameters: {
          'api': 'SYNO.Core.System.Utilization',
          'method': 'get',
          'version': '1',
          'type': 'current',
        },
      );

      final infoData =
          infoResponse.data is Map && infoResponse.data['success'] == true
              ? (infoResponse.data['data'] as Map? ?? const {})
              : const {};
      final utilizationData = utilizationResponse.data is Map &&
              utilizationResponse.data['success'] == true
          ? (utilizationResponse.data['data'] as Map? ?? const {})
          : const {};

      final memory = utilizationData['memory'] as Map? ?? const {};
      final network = utilizationData['network'] as List? ?? const [];
      final disk = utilizationData['disk'] as Map? ?? const {};
      final networkTotals = _extractNetworkTotals(network);
      final networkInterfaces = _extractNetworkInterfaces(network);
      final diskTotals = _extractDiskTotals(disk);
      final disks = _extractDiskStatuses(disk);
      final space = utilizationData['space'] as Map? ?? const {};
      final totalSpace = space['total'] as Map? ?? const {};
      final volumeList = _extractVolumeList(space);
      final volumePerformances = _extractVolumePerformanceStatuses(space);

      final mappedVolumes = volumeList
          .whereType<Map>()
          .map(
            (item) => StorageVolumeStatusModel(
              name: (item['display_name'] ??
                      item['device'] ??
                      item['name'] ??
                      'volume')
                  .toString(),
              usage: ((item['utilization'] as num?) ?? 0).toDouble(),
              usedBytes: _toDouble(
                item['used_size'] ??
                    item['used'] ??
                    item['volume_status']?['used_size'] ??
                    item['volume_status']?['used'],
              ),
              totalBytes: _toDouble(
                item['total_size'] ??
                    item['total'] ??
                    item['volume_status']?['totalspace'] ??
                    item['volume_status']?['total'],
              ),
            ),
          )
          .toList();

      final storagePollVolumes = await _fetchStoragePollVolumes(
        client: client,
        sid: connectionStore.session?.sid ?? '',
        synoToken: connectionStore.session?.synoToken,
      );
      final resolvedVolumes =
          storagePollVolumes.isNotEmpty ? storagePollVolumes : mappedVolumes;

      final systemHealthUptime = await _fetchSystemHealthUptime(
        client: client,
        sid: connectionStore.session?.sid ?? '',
        synoToken: connectionStore.session?.synoToken,
      );
      final versionText = _buildVersionText(infoData);
      final resolvedStorageUsage =
          _resolveStorageUsage(totalSpace, resolvedVolumes);

      final result = SystemStatusModel(
        serverName:
            (infoData['hostname'] ?? infoData['server_name'] ?? '我的 NAS')
                .toString(),
        dsmVersion: versionText,
        cpuUsage: ((utilizationData['cpu']?['user_load'] as num?) ?? 0)
                .toDouble() +
            ((utilizationData['cpu']?['system_load'] as num?) ?? 0).toDouble() +
            ((utilizationData['cpu']?['other_load'] as num?) ?? 0).toDouble(),
        cpuUserUsage:
            ((utilizationData['cpu']?['user_load'] as num?) ?? 0).toDouble(),
        cpuSystemUsage:
            ((utilizationData['cpu']?['system_load'] as num?) ?? 0).toDouble(),
        cpuIoWaitUsage:
            ((utilizationData['cpu']?['other_load'] as num?) ?? 0).toDouble(),
        load1:
            (((utilizationData['cpu']?['1min_load'] as num?) ?? 0).toDouble()) /
                100,
        load5:
            (((utilizationData['cpu']?['5min_load'] as num?) ?? 0).toDouble()) /
                100,
        load15: (((utilizationData['cpu']?['15min_load'] as num?) ?? 0)
                .toDouble()) /
            100,
        memoryUsage: ((memory['real_usage'] as num?) ?? 0).toDouble(),
        memoryTotalBytes:
            (((memory['memory_size'] as num?) ?? 0).toDouble()) * 1024,
        memoryUsedBytes: ((((memory['real_usage'] as num?) ?? 0).toDouble()) *
            (((memory['memory_size'] as num?) ?? 0).toDouble()) *
            10.24),
        memoryBufferBytes:
            (((memory['buffer'] as num?) ?? 0).toDouble()) * 1024,
        memoryCachedBytes:
            (((memory['cached'] as num?) ?? 0).toDouble()) * 1024,
        memoryAvailableBytes:
            (((memory['avail_real'] as num?) ?? 0).toDouble()) * 1024,
        storageUsage: resolvedStorageUsage,
        networkUploadBytesPerSecond: networkTotals.$1,
        networkDownloadBytesPerSecond: networkTotals.$2,
        diskReadBytesPerSecond: diskTotals.$1,
        diskWriteBytesPerSecond: diskTotals.$2,
        networkInterfaces: networkInterfaces,
        disks: disks,
        volumePerformances: volumePerformances,
        volumes: resolvedVolumes,
        modelName: (infoData['model'] ?? infoData['modelname'])?.toString(),
        serialNumber:
            (infoData['serial'] ?? infoData['serial_number'])?.toString(),
        uptimeText: systemHealthUptime ??
            _formatUptime(infoData['uptime'] ?? infoData['uptime_seconds']),
      );

      DsmLogger.success(
        module: 'System',
        action: 'fetchOverview',
        path: _baseUrl,
        response: {
          'serverName': result.serverName,
          'dsmVersion': result.dsmVersion,
          'volumes': result.volumes.length,
          'uptimeText': result.uptimeText,
        },
      );

      return result;
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchOverview',
        path: _baseUrl,
        reason: e.toString(),
        sid: _sid,
        synoToken: _synoToken,
        cookieHeader: _cookieHeader,
      );
      rethrow;
    }
  }

  @override
  Stream<SystemStatusModel> watchUtilization() {
    final synoToken = _synoToken;
    final cookieHeader = _cookieHeader;
    if (synoToken == null || synoToken.isEmpty) {
      throw Exception('Missing SynoToken for realtime utilization');
    }
    final baseUrl = _baseUrl;
    final controller = StreamController<SystemStatusModel>();

    DsmLogger.request(
      module: 'System',
      action: 'watchUtilization',
      method: 'WS',
      path: _baseUrl,
      sid: _sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.System.Utilization',
        'type': 'current',
      },
    );

    Future<void>(() async {
      final origin = _buildOrigin(baseUrl);
      final pollingState = await _openPollingSession(
        baseUrl: baseUrl,
        synoToken: synoToken,
        cookieHeader: cookieHeader,
        origin: origin,
      );

      final wsUri = _buildWebSocketUri(
        baseUrl: baseUrl,
        engineSid: pollingState.engineSid,
        synoToken: synoToken,
      );

      final headers = <String, dynamic>{
        'Origin': origin,
      };
      final combinedCookie =
          _mergeCookieHeaders(cookieHeader, pollingState.cookieHeader);
      if (combinedCookie != null && combinedCookie.isNotEmpty) {
        headers['Cookie'] = combinedCookie;
      }

      debugPrint('[WS][Connect] url=$wsUri');
      debugPrint(
          '[WS][Connect] origin=$origin cookie=${combinedCookie == null || combinedCookie.isEmpty ? 'missing' : 'present'} engineSid=${pollingState.engineSid}');

      final socket = await WebSocket.connect(
        wsUri.toString(),
        headers: headers,
      );

      debugPrint('[WS][Connected]');

      int requestIndex = 20;
      bool requested = false;
      bool terminalStateReached = false;
      Timer? bootstrapTimer;

      void sendFrame(String frame) {
        socket.add(frame);
        debugPrint('[WS][Send] $frame');
      }

      void sendRequestWebApi(String api, int version, String method,
          Map<String, dynamic> payload) {
        final index = requestIndex++;
        final frame = '42$index${jsonEncode([
              "request_webapi",
              api,
              version,
              method,
              payload
            ])}';
        sendFrame(frame);
      }

      void requestCurrent() {
        sendRequestWebApi('SYNO.Core.System.Utilization', 1, 'get', {
          'type': 'current',
          'SynoToken': synoToken,
        });
        requested = true;
      }

      void failAuth(String reason) {
        if (terminalStateReached || controller.isClosed) {
          return;
        }
        terminalStateReached = true;
        bootstrapTimer?.cancel();
        DsmLogger.failure(
          module: 'System',
          action: 'watchUtilization',
          path: _baseUrl,
          reason: 'Realtime authentication error: $reason',
          sid: _sid,
          synoToken: synoToken,
          cookieHeader: cookieHeader,
        );
        controller
            .addError(Exception('Realtime authentication error: $reason'));
        socket.close();
      }

      void failBootstrapTimeout() {
        if (terminalStateReached || controller.isClosed) {
          return;
        }
        terminalStateReached = true;
        bootstrapTimer?.cancel();
        DsmLogger.failure(
          module: 'System',
          action: 'watchUtilization',
          path: _baseUrl,
          reason:
              'Realtime bootstrap timeout after websocket connect; auth likely expired',
          sid: _sid,
          synoToken: synoToken,
          cookieHeader: cookieHeader,
        );
        controller.addError(Exception(
            'Realtime bootstrap timeout after websocket connect; auth likely expired'));
        socket.close();
      }

      sendFrame('2probe');
      sendFrame('5');
      sendFrame('40');
      requestCurrent();

      bootstrapTimer = Timer(const Duration(seconds: 2), failBootstrapTimeout);
      Timer? periodicTimer;

      void startPeriodicTimer() {
        periodicTimer?.cancel();
        periodicTimer = Timer.periodic(
          const Duration(seconds: AppConstants.realtimeRequestIntervalSeconds),
          (_) => requestCurrent(),
        );
      }

      controller.onCancel = () async {
        debugPrint('[WS][Closed by client]');
        bootstrapTimer?.cancel();
        periodicTimer?.cancel();
        await socket.close();
      };

      socket.listen(
        (rawMessage) {
          final text = rawMessage?.toString() ?? '';
          debugPrint('[WS][Frame] $text');

          if (text == '2') {
            sendFrame('3');
            return;
          }

          if (text == '3probe') {
            sendFrame('5');
            return;
          }

          if (text.startsWith('0')) {
            sendFrame('40');
            return;
          }

          if (text == '40') {
            if (!requested) {
              requestCurrent();
            }
            return;
          }

          if (_isAuthenticationErrorFrame(text)) {
            failAuth(text);
            return;
          }

          final payload = _extractRequestWebApiPayload(text);
          if (payload == null) {
            return;
          }

          if (payload['success'] != true) {
            if (_payloadLooksLikeAuthFailure(payload)) {
              failAuth(jsonEncode(payload));
            }
            return;
          }

          terminalStateReached = true;
          bootstrapTimer?.cancel();
          startPeriodicTimer();

          final data = payload['data'] as Map? ?? const {};
          final spacePreview = data['space'];
          DsmLogger.success(
            module: 'System',
            action: 'watchUtilization',
            path: _baseUrl,
            response: {
              'received': true,
              'spaceKeys': spacePreview is Map
                  ? spacePreview.keys.map((e) => e.toString()).toList()
                  : [],
            },
          );

          final cpu = data['cpu'] as Map? ?? const {};
          final memory = data['memory'] as Map? ?? const {};
          final network = data['network'] as List? ?? const [];
          final disk = data['disk'] as Map? ?? const {};
          final networkTotals = _extractNetworkTotals(network);
          final networkInterfaces = _extractNetworkInterfaces(network);
          final diskTotals = _extractDiskTotals(disk);
          final disks = _extractDiskStatuses(disk);
          final space = data['space'] as Map? ?? const {};
          final totalSpace = space['total'] as Map? ?? const {};
          final volumeList = _extractVolumeList(space);
          final volumePerformances = _extractVolumePerformanceStatuses(space);
          final mappedVolumes = volumeList
              .whereType<Map>()
              .map(
                (item) => StorageVolumeStatusModel(
                  name: (item['display_name'] ??
                          item['device'] ??
                          item['name'] ??
                          'volume')
                      .toString(),
                  usage: ((item['utilization'] as num?) ?? 0).toDouble(),
                  usedBytes: _toDouble(
                    item['used_size'] ??
                        item['used'] ??
                        item['volume_status']?['used_size'] ??
                        item['volume_status']?['used'],
                  ),
                  totalBytes: _toDouble(
                    item['total_size'] ??
                        item['total'] ??
                        item['volume_status']?['totalspace'] ??
                        item['volume_status']?['total'],
                  ),
                ),
              )
              .toList();

          DsmLogger.success(
            module: 'System',
            action: 'watchUtilizationVolumes',
            path: _baseUrl,
            response: {
              'count': mappedVolumes.length,
              'names': mappedVolumes.map((e) => e.name).toList(),
            },
          );

          controller.add(
            SystemStatusModel(
              serverName: '我的 NAS',
              dsmVersion: 'DSM 7',
              cpuUsage: ((cpu['user_load'] as num?) ?? 0).toDouble() +
                  ((cpu['system_load'] as num?) ?? 0).toDouble() +
                  ((cpu['other_load'] as num?) ?? 0).toDouble(),
              cpuUserUsage: ((cpu['user_load'] as num?) ?? 0).toDouble(),
              cpuSystemUsage: ((cpu['system_load'] as num?) ?? 0).toDouble(),
              cpuIoWaitUsage: ((cpu['other_load'] as num?) ?? 0).toDouble(),
              load1: (((cpu['1min_load'] as num?) ?? 0).toDouble()) / 100,
              load5: (((cpu['5min_load'] as num?) ?? 0).toDouble()) / 100,
              load15: (((cpu['15min_load'] as num?) ?? 0).toDouble()) / 100,
              memoryUsage: ((memory['real_usage'] as num?) ?? 0).toDouble(),
              memoryTotalBytes:
                  (((memory['memory_size'] as num?) ?? 0).toDouble()) * 1024,
              memoryUsedBytes:
                  ((((memory['real_usage'] as num?) ?? 0).toDouble()) *
                      (((memory['memory_size'] as num?) ?? 0).toDouble()) *
                      10.24),
              memoryBufferBytes:
                  (((memory['buffer'] as num?) ?? 0).toDouble()) * 1024,
              memoryCachedBytes:
                  (((memory['cached'] as num?) ?? 0).toDouble()) * 1024,
              memoryAvailableBytes:
                  (((memory['avail_real'] as num?) ?? 0).toDouble()) * 1024,
              storageUsage:
                  ((totalSpace['utilization'] as num?) ?? 0).toDouble(),
              networkUploadBytesPerSecond: networkTotals.$1,
              networkDownloadBytesPerSecond: networkTotals.$2,
              diskReadBytesPerSecond: diskTotals.$1,
              diskWriteBytesPerSecond: diskTotals.$2,
              networkInterfaces: networkInterfaces,
              disks: disks,
              volumePerformances: volumePerformances,
              volumes: mappedVolumes,
              uptimeText: null,
            ),
          );
        },
        onError: (error) {
          debugPrint('[WS][Error] $error');
          bootstrapTimer?.cancel();
          periodicTimer?.cancel();
          controller.addError(error);
        },
        onDone: () {
          debugPrint('[WS][Done]');
          bootstrapTimer?.cancel();
          periodicTimer?.cancel();
          controller.close();
        },
        cancelOnError: false,
      );
    }).catchError((error) {
      debugPrint('[WS][Connect Error] $error');
      controller.addError(error);
    });

    return controller.stream;
  }

  Future<_PollingState> _openPollingSession({
    required String baseUrl,
    required String synoToken,
    required String origin,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final headers = <String, dynamic>{
      'Origin': origin,
    };
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }

    final uri = _buildPollingUri(baseUrl: baseUrl, synoToken: synoToken);
    debugPrint('[EIO][Polling Open] url=$uri');

    final response = await client.getUri(
      uri,
      options: Options(headers: headers, responseType: ResponseType.plain),
    );

    final raw = response.data?.toString() ?? '';
    debugPrint('[EIO][Polling Open][Response] $raw');

    final engineSid = _extractEngineSid(raw);
    if (engineSid == null || engineSid.isEmpty) {
      throw Exception(
          'Failed to extract engine sid from polling response: $raw');
    }

    final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
    final newCookieHeader = _buildCookieHeader(setCookies);

    return _PollingState(
      engineSid: engineSid,
      cookieHeader: newCookieHeader,
    );
  }

  Uri _buildPollingUri({
    required String baseUrl,
    required String synoToken,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final basePath = baseUri.path == '/' ? '' : baseUri.path;

    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '$basePath/synoscgi.sock/socket.io/',
      queryParameters: {
        'Version': '86009',
        'SynoToken': synoToken,
        'UserType': 'user',
        'EIO': '3',
        'transport': 'polling',
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Uri _buildWebSocketUri({
    required String baseUrl,
    required String engineSid,
    required String synoToken,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final basePath = baseUri.path == '/' ? '' : baseUri.path;

    return Uri(
      scheme: scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '$basePath/synoscgi.sock/socket.io/',
      queryParameters: {
        'Version': '86009',
        'SynoToken': synoToken,
        'UserType': 'user',
        'EIO': '3',
        'transport': 'websocket',
        'sid': engineSid,
      },
    );
  }

  String _buildOrigin(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final host = uri.host;
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$portPart';
  }

  String? _extractEngineSid(String raw) {
    final match = RegExp(r'\{"sid":"([^"]+)"').firstMatch(raw);
    return match?.group(1);
  }

  bool _isAuthenticationErrorFrame(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('authentication error') ||
        normalized.contains('invalid sid') ||
        normalized.contains('unauthorized');
  }

  bool _payloadLooksLikeAuthFailure(Map<String, dynamic> payload) {
    final code = payload['code']?.toString();
    final errors = payload['errors'];
    final text = jsonEncode(payload).toLowerCase();

    if (code == '119') {
      return true;
    }

    if (errors is Map) {
      final errorCode = errors['code']?.toString();
      if (errorCode == '119') {
        return true;
      }
    }

    return text.contains('authentication error') ||
        text.contains('invalid sid') ||
        text.contains('synotoken') ||
        text.contains('unauthorized') ||
        text.contains('auth');
  }

  String? _buildCookieHeader(List<String> setCookies) {
    if (setCookies.isEmpty) return null;

    final pairs = <String>[];
    for (final cookie in setCookies) {
      final firstPart = cookie.split(';').first.trim();
      if (firstPart.isNotEmpty && firstPart.contains('=')) {
        pairs.add(firstPart);
      }
    }

    if (pairs.isEmpty) return null;
    return pairs.join('; ');
  }

  String? _mergeCookieHeaders(String? a, String? b) {
    final parts = <String>[];
    if (a != null && a.isNotEmpty) {
      parts.addAll(a.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (b != null && b.isNotEmpty) {
      parts.addAll(b.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (parts.isEmpty) return null;

    final cookieMap = <String, String>{};
    for (final part in parts) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final key = part.substring(0, idx).trim();
      final value = part.substring(idx + 1).trim();
      cookieMap[key] = value;
    }

    return cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Map<String, dynamic>? _extractRequestWebApiPayload(dynamic rawMessage) {
    final text = rawMessage?.toString() ?? '';
    final match = RegExp(r'^43\d+(\[.*\])$').firstMatch(text);
    if (match == null) {
      return null;
    }

    final jsonText = match.group(1)!;
    final decoded = jsonDecode(jsonText);
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    final payload = decoded.first;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  Future<List<StorageVolumeStatusModel>> _fetchStoragePollVolumes({
    required Dio client,
    required String sid,
    String? synoToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (synoToken != null && synoToken.isNotEmpty) {
        headers['X-SYNO-TOKEN'] = synoToken;
      }

      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.System',
          'method': 'poll',
          'version': '1',
          'type': jsonEncode('storage'),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) return const [];
      final payload = data['data'] as Map? ?? const {};
      final volInfo = (payload['vol_info'] as List?) ?? const [];

      final result = volInfo.whereType<Map>().map((item) {
        final total = _toDouble(item['total_size']);
        final used = _toDouble(item['used_size']);
        final usage = total != null && total > 0 && used != null
            ? (used / total) * 100
            : 0.0;
        return StorageVolumeStatusModel(
          name: (item['name'] ?? item['volume'] ?? 'volume').toString(),
          usage: usage,
          usedBytes: used,
          totalBytes: total,
        );
      }).toList();

      DsmLogger.success(
        module: 'System',
        action: 'fetchStoragePollVolumes',
        path: 'SYNO.Core.System.poll(storage)',
        response: {
          'count': result.length,
          'names': result.map((e) => e.name).toList(),
        },
      );

      return result;
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchStoragePollVolumes',
        reason: e.toString(),
        sid: sid,
        synoToken: synoToken,
      );
      return const [];
    }
  }

  double _resolveStorageUsage(
      Map totalSpace, List<StorageVolumeStatusModel> volumes) {
    final direct = (totalSpace['utilization'] as num?)?.toDouble();
    if (direct != null && direct > 0) {
      return direct;
    }

    double totalUsed = 0;
    double totalCapacity = 0;
    for (final volume in volumes) {
      if (volume.usedBytes != null) totalUsed += volume.usedBytes!;
      if (volume.totalBytes != null) totalCapacity += volume.totalBytes!;
    }

    if (totalCapacity > 0) {
      return (totalUsed / totalCapacity) * 100;
    }

    return 0;
  }

  /// 检查 DSM 更新版本
  ///
  /// 返回可更新的版本号，如果没有更新返回 null。
  /// 后续实现更新检查功能时使用。
  // ignore: unused_element
  Future<String?> _fetchUpgradeVersion({
    required Dio client,
    required String sid,
    String? synoToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (synoToken != null && synoToken.isNotEmpty) {
        headers['X-SYNO-TOKEN'] = synoToken;
      }

      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Entry.Request',
          'method': 'request',
          'version': '1',
          'stop_when_error': 'false',
          'mode': 'sequential',
          'compound': jsonEncode([
            {
              'api': 'SYNO.Core.Upgrade.Server',
              'method': 'check',
              'version': 1,
              'need_auto_smallupdate': true,
            },
          ]),
        },
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) return null;

      final result = data['data']?['result'];
      if (result is! List) return null;

      for (final item in result.whereType<Map>()) {
        if (item['api']?.toString() != 'SYNO.Core.Upgrade.Server') continue;
        if (item['success'] != true) continue;

        final payload = item['data'] as Map? ?? const {};
        final version = payload['version']?.toString();
        if (version != null && version.trim().isNotEmpty) {
          return version.trim();
        }

        final details = payload['version_details'] as Map? ?? const {};
        final osName = details['os_name']?.toString() ?? 'DSM';
        final major = details['major']?.toString();
        final minor = details['minor']?.toString();
        final micro = details['micro']?.toString();
        final nano = details['nano']?.toString();
        final build = details['buildnumber']?.toString();

        final parts = <String>[];
        if (major != null && major.isNotEmpty) {
          var versionNumber = major;
          if (minor != null && minor.isNotEmpty) versionNumber += '.$minor';
          if (micro != null && micro.isNotEmpty) versionNumber += '.$micro';
          if (nano != null && nano.isNotEmpty && nano != '0') {
            versionNumber += ' Update $nano';
          }
          parts.add('$osName $versionNumber');
        }
        if (build != null && build.isNotEmpty) {
          if (parts.isEmpty) {
            parts.add('$osName $build');
          } else {
            parts[0] = parts[0].replaceFirst(' Update', '-$build Update');
            if (!parts[0].contains('-$build')) {
              parts[0] = '${parts[0]}-$build';
            }
          }
        }

        if (parts.isNotEmpty) {
          return parts.first.trim();
        }
      }
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchUpgradeVersion',
        reason: e.toString(),
        sid: sid,
        synoToken: synoToken,
      );
    }

    return null;
  }

  Future<String?> _fetchSystemHealthUptime({
    required Dio client,
    required String sid,
    String? synoToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (synoToken != null && synoToken.isNotEmpty) {
        headers['X-SYNO-TOKEN'] = synoToken;
      }

      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.System.SystemHealth',
          'method': 'get',
          'version': '1',
        },
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final payload = data['data'] as Map? ?? const {};
      final uptime = payload['uptime']?.toString();
      if (uptime == null || uptime.trim().isEmpty) return null;
      return uptime.trim();
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchSystemHealthUptime',
        reason: e.toString(),
        sid: sid,
        synoToken: synoToken,
      );
    }

    return null;
  }

  String _buildVersionText(Map infoData) {
    final versionString = infoData['version_string']?.toString();
    if (versionString != null && versionString.trim().isNotEmpty) {
      return versionString.trim();
    }

    final productVersion = infoData['productversion']?.toString();
    if (productVersion != null && productVersion.trim().isNotEmpty) {
      final build = infoData['buildnumber']?.toString();
      if (build != null && build.trim().isNotEmpty) {
        return 'DSM ${productVersion.trim()}-$build';
      }
      return 'DSM ${productVersion.trim()}';
    }

    final major = infoData['productmajor']?.toString();
    final minor = infoData['productminor']?.toString();
    if (major != null && major.isNotEmpty) {
      return minor != null && minor.isNotEmpty
          ? 'DSM $major.$minor'
          : 'DSM $major';
    }

    return 'DSM 鐗堟湰鏈煡';
  }

  List<Map> _extractVolumeList(Map space) {
    final direct = space['volume'];
    if (direct is List) {
      return direct.whereType<Map>().toList();
    }

    final volumes = space['volumes'];
    if (volumes is List) {
      return volumes.whereType<Map>().toList();
    }

    final items = space['items'];
    if (items is List) {
      return items.whereType<Map>().where((item) {
        final name =
            (item['display_name'] ?? item['device'] ?? item['name'] ?? '')
                .toString()
                .toLowerCase();
        return name.startsWith('volume');
      }).toList();
    }

    return const [];
  }

  (double, double) _extractNetworkTotals(List network) {
    if (network.isEmpty) return (0, 0);

    final first = network.first;
    if (first is! Map) return (0, 0);

    return (
      _toDouble(first['tx']) ?? 0,
      _toDouble(first['rx']) ?? 0,
    );
  }

  (double, double) _extractDiskTotals(Map disk) {
    final total = disk['total'];
    if (total is! Map) return (0, 0);

    return (
      _toDouble(total['read_byte']) ?? 0,
      _toDouble(total['write_byte']) ?? 0,
    );
  }

  List<NetworkInterfaceStatusModel> _extractNetworkInterfaces(List network) {
    if (network.isEmpty) return const [];

    return network.whereType<Map>().toList().asMap().entries.map((entry) {
      final item = entry.value;
      final index = entry.key;
      final name = (item['display_name'] ?? item['name'] ?? item['id'] ?? '')
          .toString()
          .trim();
      return NetworkInterfaceStatusModel(
        name: name.isEmpty ? (index == 0 ? '鎬昏' : '灞€鍩熺綉 $index') : name,
        uploadBytesPerSecond: _toDouble(item['tx']) ?? 0,
        downloadBytesPerSecond: _toDouble(item['rx']) ?? 0,
      );
    }).toList();
  }

  List<DiskStatusModel> _extractDiskStatuses(Map disk) {
    final items = disk['disk'];
    if (items is! List) return const [];

    return items.whereType<Map>().map((item) {
      return DiskStatusModel(
        name: (item['display_name'] ?? item['name'] ?? item['device'] ?? '纾佺洏')
            .toString(),
        utilization: _toDouble(item['utilization']) ?? 0,
        readBytesPerSecond: _toDouble(item['read_byte']) ?? 0,
        writeBytesPerSecond: _toDouble(item['write_byte']) ?? 0,
        readIops: _toDouble(item['read_access']) ?? 0,
        writeIops: _toDouble(item['write_access']) ?? 0,
      );
    }).toList();
  }

  List<VolumePerformanceStatusModel> _extractVolumePerformanceStatuses(
      Map space) {
    final items = _extractVolumeList(space);
    return items.whereType<Map>().map((item) {
      return VolumePerformanceStatusModel(
        name:
            (item['display_name'] ?? item['name'] ?? item['device'] ?? '瀛樺偍绌洪棿')
                .toString(),
        utilization: _toDouble(item['utilization']) ?? 0,
        readBytesPerSecond: _toDouble(item['read_byte']) ?? 0,
        writeBytesPerSecond: _toDouble(item['write_byte']) ?? 0,
        readIops: _toDouble(item['read_access']) ?? 0,
        writeIops: _toDouble(item['write_access']) ?? 0,
      );
    }).toList();
  }

  Map _extractCompoundApiData(Map compoundResult, String targetApi) {
    final resultList = compoundResult['result'];
    if (resultList is! List) return const {};

    for (final item in resultList) {
      if (item is Map && item['api'] == targetApi && item['success'] == true) {
        final data = item['data'];
        if (data is Map) {
          return data;
        }
        if (data is List) {
          return {
            'list': data,
          };
        }
        return const {};
      }
    }
    return const {};
  }

  List<InformationCenterLanNetworkModel> _extractLanNetworks(
      Map networkData, Map ethernetData, Map gatewayListData) {
    final candidateLists = [
      ethernetData['eth'],
      ethernetData['interfaces'],
      ethernetData['list'],
      networkData['lan'],
      networkData['lans'],
      networkData['interfaces'],
      networkData['networks'],
      networkData['service'],
    ];

    for (final candidate in candidateLists) {
      if (candidate is! List) continue;
      final result = candidate.whereType<Map>().map((item) {
        final ipv4 = _extractIpv4Map(item);
        final ipAddr =
            (ipv4?['address'] ?? item['ip'] ?? item['ipaddr'])?.toString();
        return InformationCenterLanNetworkModel(
          name: (item['name'] ?? item['id'] ?? item['service'] ?? 'LAN')
              .toString(),
          macAddress: (item['mac'] ?? item['mac_address'] ?? item['hwaddr'])
              ?.toString(),
          ipAddress: ipAddr == '0.0.0.0' ? '-' : ipAddr,
          subnetMask: (ipv4?['netmask'] ?? item['mask'] ?? item['subnet_mask'])
              ?.toString(),
        );
      }).where((item) {
        return item.macAddress != null ||
            item.ipAddress != null ||
            item.subnetMask != null;
      }).toList();
      if (result.isNotEmpty) {
        return result;
      }
    }

    return const [];
  }

  Map? _extractIpv4Map(Map item) {
    final ipv4 = item['ipv4'];
    if (ipv4 is Map) return ipv4;

    final ip = item['ip'];
    if (ip is Map) return ip;

    final inet = item['inet'];
    if (inet is Map) return inet;

    return null;
  }

  List<InformationCenterExternalDeviceModel> _extractExternalDevices(
      Map usbData, Map esataData) {
    final usbDevices = _extractExternalDevicesFromMap(usbData);
    final esataDevices = _extractExternalDevicesFromMap(esataData);

    return [...usbDevices, ...esataDevices];
  }

  List<InformationCenterExternalDeviceModel> _extractExternalDevicesFromMap(
      Map externalDeviceData) {
    final lists = [
      externalDeviceData['devices'],
      externalDeviceData['esata'],
      externalDeviceData['usb'],
      externalDeviceData['list'],
    ];

    for (final candidate in lists) {
      if (candidate is! List) continue;
      final result = candidate.whereType<Map>().map((item) {
        return InformationCenterExternalDeviceModel(
          name: (item['name'] ??
                  item['display_name'] ??
                  item['dev_name'] ??
                  '澶栨帴璁惧')
              .toString(),
          type: (item['type'] ?? item['device_type'])?.toString(),
          status: (item['status'] ?? item['state'])?.toString(),
        );
      }).toList();
      if (result.isNotEmpty) {
        return result;
      }
    }

    return const [];
  }

  List<InformationCenterDiskModel> _extractDisks(Map diskData) {
    final candidateLists = [
      diskData['disks'],
      diskData['items'],
      diskData['list'],
    ];

    for (final candidate in candidateLists) {
      if (candidate is! List) continue;
      final result = candidate.whereType<Map>().map((item) {
        final tempValue =
            item['temp'] ?? item['temperature'] ?? item['smart_temp'];
        return InformationCenterDiskModel(
          name: (item['name'] ?? item['device'] ?? item['diskno'] ?? '纭洏')
              .toString(),
          serialNumber: (item['serial'] ?? item['serial_number'])?.toString(),
          capacityBytes: _toDouble(
              item['size_total'] ?? item['size'] ?? item['total_size']),
          temperatureText: _resolveTemperatureText(tempValue),
        );
      }).toList();
      if (result.isNotEmpty) {
        return result;
      }
    }

    return const [];
  }

  String? _resolveSystemTime(Map timeData) {
    final candidates = [
      timeData['time'],
      timeData['system_time'],
      timeData['current_time'],
      timeData['date_time'],
    ];
    for (final value in candidates) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String? _resolveThermalStatus(Map systemHealthData) {
    final thermal = systemHealthData['thermal'];
    if (thermal is Map) {
      final status =
          thermal['status'] ?? thermal['message'] ?? thermal['level'];
      if (status != null && status.toString().trim().isNotEmpty) {
        return status.toString().trim();
      }
    }

    final fan = systemHealthData['fan'];
    if (fan is Map) {
      final status = fan['status'] ?? fan['message'] ?? fan['level'];
      if (status != null && status.toString().trim().isNotEmpty) {
        return status.toString().trim();
      }
    }

    final candidates = [
      systemHealthData['thermal_status'],
      systemHealthData['fan_status'],
      systemHealthData['cooling_status'],
    ];
    for (final value in candidates) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String? _resolveDns(Map networkData) {
    final dnsPrimary = networkData['dns_primary'];
    final dnsSecondary = networkData['dns_secondary'];
    if (dnsPrimary != null && dnsPrimary.toString().trim().isNotEmpty) {
      if (dnsSecondary != null && dnsSecondary.toString().trim().isNotEmpty) {
        return '${dnsPrimary.toString().trim()} / ${dnsSecondary.toString().trim()}';
      }
      return dnsPrimary.toString().trim();
    }

    final dns = networkData['dns'];
    if (dns is List) {
      final values = dns
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (values.isNotEmpty) {
        return values.join(' / ');
      }
    }
    if (dns != null && dns.toString().trim().isNotEmpty) {
      return dns.toString().trim();
    }
    return networkData['dns_server']?.toString();
  }

  String? _resolveGateway(Map networkData, Map gatewayListData) {
    final gatewayList = gatewayListData['list'] ?? gatewayListData['data'];
    if (gatewayList is List && gatewayList.isNotEmpty) {
      final first = gatewayList.first;
      if (first is Map && first['gateway'] != null) {
        return first['gateway'].toString().trim();
      }
    }

    final candidates = [
      networkData['gateway'],
      networkData['default_gateway'],
      networkData['gw'],
    ];
    for (final value in candidates) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String? _resolveWorkgroup(Map networkData) {
    final candidates = [
      networkData['workgroup'],
      networkData['work_group'],
      networkData['domain'],
    ];
    for (final value in candidates) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  String? _resolveTemperatureText(dynamic value) {
    if (value == null) return null;
    final number = _toDouble(value);
    if (number == null) {
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }
    return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 1)}掳C';
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String? _formatUptime(dynamic value) {
    if (value == null) return null;
    final seconds = int.tryParse(value.toString());
    if (seconds == null) {
      return value.toString();
    }

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分钟');
    if (parts.isEmpty) parts.add('$seconds秒');
    return parts.join(' ');
  }

  @override
  Future<FileServicesModel> fetchFileServices() async {
    final client = _dio;

    Future<Map<String, dynamic>?> fetchService(String api, String method) async {
      try {
        final response = await client.post(
          '/webapi/entry.cgi',
          data: {
            'api': api,
            'method': method,
            'version': 1,
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        if (response.data is Map && response.data['success'] == true) {
          return response.data['data'] as Map<String, dynamic>?;
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    // 并行请求所有文件服务状态
    final results = await Future.wait([
      fetchService('SYNO.Core.FileServ.SMB', 'get'),
      fetchService('SYNO.Core.FileServ.NFS', 'get'),
      fetchService('SYNO.Core.FileServ.FTP', 'get'),
      fetchService('SYNO.Core.FileServ.AFP', 'get'),
      fetchService('SYNO.Core.FileServ.FTP.SFTP', 'get'),
    ]);

    return FileServiceModel.fromApiResponses(
      smbData: results[0],
      nfsData: results[1],
      ftpData: results[2],
      afpData: results[3],
      sftpData: results[4],
    );
  }

  @override
  Future<NetworkModel> fetchNetwork() async {
    final client = _dio;

    // 使用 compound 请求并行获取所有网络信息
    final apis = [
      {'api': 'SYNO.Core.Network', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Network.Ethernet', 'method': 'list', 'version': 2},
      {'api': 'SYNO.Core.Network.PPPoE', 'method': 'list', 'version': 1},
      {'api': 'SYNO.Core.Network.Proxy', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Network.Router.Gateway.List', 'method': 'get', 'version': 1, 'iptype': 'ipv4', 'type': 'wan'},
    ];

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'stop_when_error': false,
          'api': 'SYNO.Entry.Request',
          'method': 'request',
          'mode': '"sequential"',
          'compound': jsonEncode(apis),
          'version': 1,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        final result = response.data['data']?['result'] as List?;
        if (result != null) {
          return NetworkModel.fromApiResponse(result);
        }
      }

      DsmLogger.failure(
        module: 'Network',
        action: 'fetchNetwork',
        response: response.data,
        reason: '网络状态获取失败',
      );
      return const NetworkModel();
    } catch (e) {
      DsmLogger.failure(
        module: 'Network',
        action: 'fetchNetwork',
        reason: '获取网络状态异常: $e',
      );
      rethrow;
    }
  }

  @override
  Future<UpgradeStatus> checkUpgrade() async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.Upgrade.Server',
          'method': 'check',
          'version': 2,
          'user_reading': true,
          'need_auto_smallupdate': true,
          'need_promotion': true,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        return UpgradeStatus.fromApiResponse(data);
      }

      DsmLogger.failure(
        module: 'Upgrade',
        action: 'checkUpgrade',
        response: response.data,
        reason: '更新检查失败',
      );
      return UpgradeStatus.noUpdate;
    } catch (e) {
      DsmLogger.failure(
        module: 'Upgrade',
        action: 'checkUpgrade',
        reason: '检查更新异常: $e',
      );
      rethrow;
    }
  }

  @override
  Future<TerminalSettings> fetchTerminalSettings() async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.Terminal',
          'version': 3,
          'method': 'get',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        return TerminalSettings.fromApiResponse(data);
      }

      DsmLogger.failure(
        module: 'Terminal',
        action: 'fetchTerminalSettings',
        response: response.data,
        reason: '获取终端设置失败',
      );
      return const TerminalSettings(sshEnabled: false, telnetEnabled: false, sshPort: 22);
    } catch (e) {
      DsmLogger.failure(
        module: 'Terminal',
        action: 'fetchTerminalSettings',
        reason: '获取终端设置异常: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> setTerminalSettings({
    required bool sshEnabled,
    required bool telnetEnabled,
    required int sshPort,
  }) async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.Terminal',
          'version': 3,
          'method': 'set',
          'enable_ssh': sshEnabled,
          'enable_telnet': telnetEnabled,
          'ssh_port': sshPort,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] != true) {
        final error = response.data['error']?['message'] ?? '设置终端失败';
        throw Exception(error);
      }

      DsmLogger.success(
        module: 'Terminal',
        action: 'setTerminalSettings',
        response: {'sshEnabled': sshEnabled, 'telnetEnabled': telnetEnabled, 'sshPort': sshPort},
      );
    } catch (e) {
      DsmLogger.failure(
        module: 'Terminal',
        action: 'setTerminalSettings',
        reason: '设置终端异常: $e',
      );
      rethrow;
    }
  }
}

class _PollingState {
  final String engineSid;
  final String? cookieHeader;

  const _PollingState({
    required this.engineSid,
    this.cookieHeader,
  });
}
