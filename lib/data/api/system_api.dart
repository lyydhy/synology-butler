import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/file_service.dart';
import '../../domain/entities/shared_folder.dart';
import '../models/shared_folder_model.dart';
import '../../domain/entities/power_schedule_task.dart';
import '../../domain/entities/power_status.dart';
import '../../domain/entities/terminal_settings.dart';
import '../../domain/entities/upgrade_status.dart';
import '../models/dsm_group_model.dart';
import '../models/dsm_user_model.dart';
import '../models/external_access_model.dart';
import '../models/file_service_model.dart';
import '../models/index_service_model.dart';
import '../models/information_center_model.dart';
import '../models/shared_folder_model.dart';
import '../models/system_status_model.dart';
import '../models/task_scheduler_model.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview();

  Future<InformationCenterModel> fetchInformationCenter({
    required String serverName,
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
      final networkSystemData = await postEntry({
        'api': 'SYNO.Core.System',
        'method': 'info',
        'version': '1',
        'type': 'network',
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
          _extractLanNetworks(networkSystemData, networkData, ethernetData, gatewayListData);
      final externalDevices = _extractExternalDevices(usbData, esataData);
      final disks = _extractDisks(diskData);
      final versionText = _buildVersionText(infoData);

      int cpuCores = _toInt(infoData['cpu_cores']) ?? int.tryParse(infoData['cpu_cores']?.toString() ?? '') ?? 0;
      // cpu_clock_speed 单位为 kHz，转 GHz 需除以 1000000；为兼容显示，仍除以 1000 转 MHz 后显示
      double cpuClockSpeed = (_toDouble(infoData['cpu_clock_speed']) ?? 0) / 1000;
      String cpuClockSpeedStr = cpuClockSpeed.toStringAsFixed(2);
      final model = InformationCenterModel(
          serverName:
              (infoData['hostname'] ?? infoData['server_name'] ?? serverName)
                  .toString(),
          serialNumber:
              (infoData['serial'] ?? infoData['serial_number'])?.toString(),
          modelName: (infoData['model'] ?? infoData['modelname'])?.toString(),
          cpuName:
              [infoData['cpu_vendor'], infoData['cpu_family'], infoData['cpu_series']].where((s) => s != null && s.toString().trim().isNotEmpty).join(' '),
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
          dnsServer: _resolveDns(networkSystemData),
          gateway: _resolveGateway(networkSystemData, gatewayListData),
          workgroup: _resolveWorkgroup(networkSystemData),
          externalDevices: externalDevices,
          lanNetworks: networks,
          disks: disks,
          sysTemp: _toInt(infoData['sys_temp']),
          time: infoData['time'],
          temperatureWarning: infoData['temperature_warning']);

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

  // ─── Helper methods ───────────────────────────────────────────────────────────

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
        name: name.isEmpty ? (index == 0 ? '总流量' : '局域网 $index') : name,
        uploadBytesPerSecond: _toDouble(item['tx']) ?? 0,
        downloadBytesPerSecond: _toDouble(item['rx']) ?? 0,
      );
    }).toList();
  }

  List<DiskStatusModel> _extractDiskStatuses(Map disk) {
    final devices = disk['device'] as List? ?? const [];
    return devices.whereType<Map>().toList().asMap().entries.map((entry) {
      final item = entry.value;
      return DiskStatusModel(
        name: (item['name'] ?? item['diskno'] ?? 'disk${entry.key}').toString(),
        utilization: (item['utilization'] as num?)?.toDouble() ?? 0,
        readBytesPerSecond: _toDouble(item['read_byte']) ?? 0,
        writeBytesPerSecond: _toDouble(item['write_byte']) ?? 0,
        readIops: _toDouble(item['read_iops']) ?? 0,
        writeIops: _toDouble(item['write_iops']) ?? 0,
      );
    }).toList();
  }

  List<VolumePerformanceStatusModel> _extractVolumePerformanceStatuses(Map space) {
    final volumePerf = space['volume_performance'] as Map? ?? {};
    if (volumePerf.isEmpty) return const [];

    return volumePerf.entries.whereType<MapEntry>().map((entry) {
      final item = entry.value as Map? ?? {};
      return VolumePerformanceStatusModel(
        name: entry.key.toString(),
        utilization: (item['utilization'] as num?)?.toDouble() ?? 0,
        readBytesPerSecond: _toDouble(item['read_byte']) ?? 0,
        writeBytesPerSecond: _toDouble(item['write_byte']) ?? 0,
        readIops: _toDouble(item['read_iops']) ?? 0,
        writeIops: _toDouble(item['write_iops']) ?? 0,
      );
    }).toList();
  }

  Map<String, dynamic> _extractCompoundApiData(Map compound, String api) {
    final result = compound[api] as Map?;
    return Map<String, dynamic>.from(result ?? const {});
  }

  List<InformationCenterLanNetworkModel> _extractLanNetworks(
    Map networkSystemData,
    Map networkData,
    Map ethernetData,
    Map gatewayListData,
  ) {
    final interfaces = <InformationCenterLanNetworkModel>[];

    // dsm_helper style: SYNO.Core.System type=network returns nif list with mac/addr/mask
    final nifList = networkData['nif'] as List? ?? const [];
    for (final nif in nifList.whereType<Map>()) {
      final mac = (nif['mac'] ?? '').toString();
      if (mac.isEmpty) continue;
      final addr = (nif['addr'] ?? '').toString();
      interfaces.add(InformationCenterLanNetworkModel(
        name: '局域网 ${interfaces.length + 1}',
        macAddress: mac,
        ipAddress: addr,
        subnetMask: (nif['mask'] ?? nif['subnet_mask'] ?? '').toString(),
      ));
    }

    // Fallback: try SYNO.Core.Network.Ethernet eth list
    if (interfaces.isEmpty) {
      final ethernetList = ethernetData['eth'] as List? ?? const [];
      for (final eth in ethernetList.whereType<Map>()) {
        final name = (eth['name'] ?? eth['device'] ?? '').toString();
        if (name.isEmpty) continue;
        interfaces.add(InformationCenterLanNetworkModel(
          name: name,
          macAddress: (eth['mac'] ?? '').toString(),
          ipAddress: (eth['ip'] ?? '').toString(),
          subnetMask: (eth['mask'] ?? eth['subnet_mask'] ?? '').toString(),
        ));
      }
    }

    return interfaces;
  }

  List<InformationCenterExternalDeviceModel> _extractExternalDevices(Map usbData, Map esataData) {
    final devices = <InformationCenterExternalDeviceModel>[];

    for (final item in (usbData['devices'] as List? ?? const []).whereType<Map>()) {
      devices.add(InformationCenterExternalDeviceModel(
        name: (item['display_name'] ?? item['name'] ?? item['device_name'] ?? '').toString(),
        type: 'usb',
        status: (item['status'] ?? item['device_status'] ?? '').toString(),
      ));
    }

    for (final item in (esataData['devices'] as List? ?? const []).whereType<Map>()) {
      devices.add(InformationCenterExternalDeviceModel(
        name: (item['display_name'] ?? item['name'] ?? item['device_name'] ?? '').toString(),
        type: 'esata',
        status: (item['status'] ?? item['device_status'] ?? '').toString(),
      ));
    }

    return devices;
  }

  List<InformationCenterDiskModel> _extractDisks(Map diskData) {
    final disks = <InformationCenterDiskModel>[];
    final items = diskData['disks'] as List? ?? (diskData['items'] as List?) ?? (diskData['list'] as List?) ?? const [];

    for (final item in items.whereType<Map>()) {
      final name = (item['name'] ?? item['device'] ?? item['diskno'] ?? '').toString();
      if (name.isEmpty) continue;

      disks.add(InformationCenterDiskModel(
        name: name,
        serialNumber: (item['serial'] ?? '').toString(),
        capacityBytes: _toDouble(item['size_total'] ?? item['size']),
        temperatureText: _toInt(item['temp'] ?? item['temperature'])?.toString(),
      ));
    }

    return disks;
  }

  String _buildVersionText(Map infoData) {
    // 优先使用 firmware_ver（dsm_helper 使用的字段，DSM 7 常见）
    final firmwareVer = infoData['firmware_ver']?.toString();
    if (firmwareVer != null && firmwareVer.trim().isNotEmpty) {
      return firmwareVer.trim();
    }

    // 其次使用 version_string
    final versionString = infoData['version_string']?.toString();
    if (versionString != null && versionString.trim().isNotEmpty) {
      return versionString.trim();
    }

    // 其次使用 productversion + buildnumber
    final productVersion = infoData['productversion']?.toString();
    if (productVersion != null && productVersion.trim().isNotEmpty) {
      final build = infoData['buildnumber']?.toString();
      if (build != null && build.trim().isNotEmpty) {
        return 'DSM ${productVersion.trim()}-$build';
      }
      return 'DSM ${productVersion.trim()}';
    }

    // Fallback: version + build
    final version = infoData['version']?.toString();
    final build = infoData['build']?.toString();
    if (version != null || build != null) {
      return 'DSM ${version ?? ''} (${build ?? ''})'.trim().replaceAll(RegExp(r'^\s*\(|\)\s*$'), '');
    }

    return '未知';
  }

  String _formatUptime(dynamic uptime) {
    if (uptime == null) return '未知';
    final seconds = int.tryParse(uptime.toString()) ?? 0;
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}天 ${hours}小时';
    if (hours > 0) return '${hours}小时 ${minutes}分钟';
    if (minutes > 0) return '${minutes}分钟';
    return '${seconds}秒';
  }

  String? _resolveSystemTime(Map timeData) {
    final timestamp = timeData['timestamp'] ?? timeData['unixtime'];
    if (timestamp == null) return null;
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(timestamp.toString()) ?? 0) * 1000);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  String? _resolveThermalStatus(Map healthData) {
    final status = healthData['thermal_status'] ?? healthData['thermal'] ?? '';
    return status.toString().isEmpty ? null : status.toString();
  }

  String? _resolveDns(Map networkData) {
    // dsm_helper style: dns can be a string or list
    final dns = networkData['dns'];
    if (dns == null) return null;
    if (dns is String && dns.trim().isNotEmpty) return dns.trim();
    if (dns is List) {
      final nonEmpty = dns.where((e) => e.toString().trim().isNotEmpty).take(2);
      return nonEmpty.map((e) => e.toString().trim()).join(', ');
    }
    final dnsStr = dns.toString().trim();
    return dnsStr.isEmpty ? null : dnsStr;
  }

  String? _resolveGateway(Map networkData, Map gatewayListData) {
    final gateways = gatewayListData['gateway_list'] as List?;
    if (gateways != null && gateways.isNotEmpty) {
      return gateways.first.toString();
    }
    return (networkData['gateway'] ?? '').toString().replaceAll(RegExp(r'^\[|\]$'), '');
  }

  String? _resolveWorkgroup(Map networkData) {
    return (networkData['workgroup'] ?? '').toString();
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
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final payload = data['data'] as Map? ?? const {};
      return (payload['uptime'] ?? '').toString();
    } catch (_) {
      return null;
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
}

class _PollingState {
  final String engineSid;
  final String? cookieHeader;

  const _PollingState({
    required this.engineSid,
    this.cookieHeader,
  });
}
