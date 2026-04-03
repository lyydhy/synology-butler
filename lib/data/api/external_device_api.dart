import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../models/external_device_model.dart';

/// 外部设备 API
class ExternalDeviceApi {
  Dio get _dio => businessDio();

  /// 获取外部设备列表（USB/eSATA）
  Future<List<ExternalDeviceModel>> fetchExternalDevices() async {
    final client = _dio;

    Future<Map<String, dynamic>> postEntry(Map<String, dynamic> data) async {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['success'] == true) {
        return (response.data['data'] as Map?)?.cast<String, dynamic>() ?? const {};
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

    List<ExternalDeviceModel> parseDevices(Map<String, dynamic> data, String bus) {
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

  /// 弹出外部设备
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

  Map<String, dynamic> _extractCompoundApiData(Map<String, dynamic> compound, String apiName) {
    final result = (compound['result'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final item in result) {
      if (item['api'] == apiName) {
        return (item['data'] as Map<String, dynamic>?) ?? const {};
      }
    }
    return const {};
  }
}
