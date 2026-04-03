import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/information_center.dart';
import '../../domain/entities/system_status.dart';
import '../models/information_center_model.dart';
import '../models/system_status_model.dart';

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

  Map<String, dynamic> _extractCompoundApiData(Map<String, dynamic> compound, String apiName) {
    final result = (compound['result'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final item in result) {
      if (item['api'] == apiName) {
        return (item['data'] as Map<String, dynamic>?) ?? const {};
      }
    }
    return const {};
  }

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
}
