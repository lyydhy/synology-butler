import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../models/external_access_model.dart';

/// 外部访问/DDNS API
class ExternalAccessApi {
  Dio get _dio => businessDio();

  /// 获取外部访问状态（DDNS 记录）
  Future<ExternalAccessModel> fetchExternalAccess() async {
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
    final records = ((recordData['records'] as List?)?.cast<Map>() ?? const [])
        .whereType<Map<String, dynamic>>()
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

  /// 刷新 DDNS
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
