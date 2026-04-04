import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/information_center_model.dart';

/// 信息中心 API
class InformationCenterApi {
  Dio get _dio => businessDio();

  /// 获取信息中心数据
  Future<InformationCenterModel> fetchInformationCenter({
    required String serverName,
  }) async {
    final client = _dio;

    Future<Map<String, dynamic>?> postEntry(Map<String, dynamic> data) async {
      try {
        final response = await client.post(
          '/webapi/entry.cgi',
          data: data,
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        if (response.data is Map && response.data['success'] == true) {
          return response.data['data'] as Map<String, dynamic>?;
        }
        return null;
      } catch (e) {
        DsmLogger.failure(
          module: 'InformationCenter',
          action: 'postEntry',
          reason: '请求失败：$e',
        );
        return null;
      }
    }

    DsmLogger.request(
      module: 'InformationCenter',
      action: 'fetchInformationCenter',
      method: 'POST',
      extra: {
        'serverName': serverName,
        'apis': [
          'SYNO.Core.System',
          'SYNO.Core.System.Utilization',
          'SYNO.Core.System.SystemHealth',
          'SYNO.Core.System.Time',
          'SYNO.Core.Network',
          'SYNO.Core.ExternalDevice.Storage.USB',
          'SYNO.Core.ExternalDevice.Storage.eSATA',
          'SYNO.Core.Storage.Disk',
        ],
      },
    );

    try {
      // 并行获取所有信息
      final results = await Future.wait([
        postEntry({
          'api': 'SYNO.Core.System',
          'method': 'info',
          'version': '1',
        }),
        postEntry({
          'api': 'SYNO.Core.System.Utilization',
          'method': 'get',
          'version': '1',
          'type': 'current',
        }),
        postEntry({
          'api': 'SYNO.Core.System.SystemHealth',
          'method': 'get',
          'version': '1',
        }),
        postEntry({
          'api': 'SYNO.Core.System.Time',
          'method': 'get',
          'version': '1',
        }),
        _fetchNetworkData(client),
        _fetchExternalDevices(client),
        postEntry({
          'api': 'SYNO.Core.Storage.Disk',
          'method': 'list',
          'version': '1',
          'additional': jsonEncode(['size_total', 'temp', 'serial']),
        }),
      ]);

      final infoData = results[0] ?? const {};
      final utilizationData = results[1] ?? const {};
      final systemHealthData = results[2] ?? const {};
      final timeData = results[3] ?? const {};
      final networkCompoundData = results[4] ?? const {};
      final externalDeviceCompoundData = results[5] ?? const {};
      final diskData = results[6] ?? const {};

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

      int cpuCores = int.tryParse(infoData['cpu_cores']?.toString() ?? '') ?? 0;
      double cpuClockSpeed =
          (_toInt(infoData['cpu_clock_speed']) ?? 0) / 1000;
      String cpuClockSpeedStr = (cpuClockSpeed / 1000).toStringAsFixed(2);

      final model = InformationCenterModel(
        serverName: (infoData['hostname'] ??
                infoData['server_name'] ??
                serverName)
            .toString(),
        serialNumber:
            (infoData['serial'] ?? infoData['serial_number'])?.toString(),
        modelName: (infoData['model'] ?? infoData['modelname'])?.toString(),
        cpuName:
            "${infoData['cpu_vendor']} ${infoData['cpu_family']} ${infoData['cpu_series']}",
        cpuCores: cpuCores,
        cpuClockSpeedStr: "$cpuCores 核 @ ${cpuClockSpeedStr}GHz",
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
        temperatureWarning: infoData['temperature_warning'] == true,
      );

      DsmLogger.success(
        module: 'InformationCenter',
        action: 'fetchInformationCenter',
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
        module: 'InformationCenter',
        action: 'fetchInformationCenter',
        reason: '获取信息中心数据异常：$e',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchNetworkData(Dio client) async {
    try {
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
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      DsmLogger.failure(
        module: 'InformationCenter',
        action: '_fetchNetworkData',
        reason: '获取网络数据失败：$e',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchExternalDevices(Dio client) async {
    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
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
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      DsmLogger.failure(
        module: 'InformationCenter',
        action: '_fetchExternalDevices',
        reason: '获取外接设备失败：$e',
      );
      return null;
    }
  }

  Map<String, dynamic> _extractCompoundApiData(
      Map<String, dynamic> compoundResult, String targetApi) {
    final resultList = compoundResult['result'] as List?;
    if (resultList == null) return const {};

    for (final item in resultList) {
      if (item is Map &&
          item['api'] == targetApi &&
          item['success'] == true) {
        final data = item['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        if (data is List) {
          return {'list': data};
        }
        return const {};
      }
    }
    return const {};
  }

  List<InformationCenterLanNetworkModel> _extractLanNetworks(
      Map<String, dynamic> networkData,
      Map<String, dynamic> ethernetData,
      Map<String, dynamic> gatewayListData) {
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
          macAddress:
              (item['mac'] ?? item['mac_address'] ?? item['hwaddr'])?.toString(),
          ipAddress: ipAddr == '0.0.0.0' ? '-' : ipAddr,
          subnetMask:
              (ipv4?['netmask'] ?? item['mask'] ?? item['subnet_mask'])?.toString(),
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
      Map<String, dynamic> usbData, Map<String, dynamic> esataData) {
    final usbDevices = _extractExternalDevicesFromMap(usbData);
    final esataDevices = _extractExternalDevicesFromMap(esataData);
    return [...usbDevices, ...esataDevices];
  }

  List<InformationCenterExternalDeviceModel>
      _extractExternalDevicesFromMap(Map<String, dynamic> externalDeviceData) {
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
                  '外接设备')
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

  List<InformationCenterDiskModel> _extractDisks(Map<String, dynamic> diskData) {
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
          name: (item['name'] ?? item['device'] ?? item['diskno'] ?? '硬盘')
              .toString(),
          serialNumber: (item['serial'] ?? item['serial_number'])?.toString(),
          capacityBytes:
              _toDouble(item['size_total'] ?? item['size'] ?? item['total_size']),
          temperatureText: _resolveTemperatureText(tempValue),
        );
      }).toList();
      if (result.isNotEmpty) {
        return result;
      }
    }

    return const [];
  }

  String? _resolveSystemTime(Map<String, dynamic> timeData) {
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

  String? _resolveThermalStatus(Map<String, dynamic> systemHealthData) {
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

  String? _resolveDns(Map<String, dynamic> networkData) {
    final dnsPrimary = networkData['dns_primary'];
    final dnsSecondary = networkData['dns_secondary'];
    if (dnsPrimary != null && dnsPrimary.toString().trim().isNotEmpty) {
      if (dnsSecondary != null &&
          dnsSecondary.toString().trim().isNotEmpty) {
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

  String? _resolveGateway(
      Map<String, dynamic> networkData, Map<String, dynamic> gatewayListData) {
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

  String? _resolveWorkgroup(Map<String, dynamic> networkData) {
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
    return '${number.toStringAsFixed(number % 1 == 0 ? 0 : 1)}°C';
  }

  String _buildVersionText(Map<String, dynamic> infoData) {
    // 优先使用 version_string
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

    // 再次使用 productmajor + productminor
    final major = infoData['productmajor']?.toString();
    final minor = infoData['productminor']?.toString();
    if (major != null && major.isNotEmpty) {
      return minor != null && minor.isNotEmpty
          ? 'DSM $major.$minor'
          : 'DSM $major';
    }

    return 'DSM';
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
    if (days > 0) parts.add('$days 天');
    if (hours > 0) parts.add('$hours 小时');
    if (minutes > 0) parts.add('$minutes 分钟');
    if (parts.isEmpty) parts.add('$seconds 秒');
    return parts.join(' ');
  }
}
