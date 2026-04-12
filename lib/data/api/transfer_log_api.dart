import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';

/// 传输日志 API
class TransferLogApi {
  Dio get _dio => businessDio();

  /// 获取传输日志状态
  Future<Map<String, bool>> fetchTransferLogStatus() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.SyslogClient.FileTransfer',
        'method': 'get',
        'version': '1',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '获取传输日志状态失败' : '获取传输日志状态失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    return {
      'cifs': data['cifs'] == true || data['cifs'] == '1' || data['cifs'] == 1,
      'afp': data['afp'] == true || data['afp'] == '1' || data['afp'] == 1,
    };
  }

  /// 设置传输日志状态
  Future<void> setTransferLogStatus({bool? cifsEnabled, bool? afpEnabled}) async {
    final client = _dio;
    final setData = <String, String>{};
    
    if (cifsEnabled != null) setData['cifs'] = cifsEnabled ? '1' : '0';
    if (afpEnabled != null) setData['afp'] = afpEnabled ? '1' : '0';

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.SyslogClient.FileTransfer',
        'method': 'set',
        'version': '1',
        ...setData,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '设置传输日志状态失败' : '设置传输日志状态失败');
    }
  }

  /// 获取传输日志级别设置
  Future<Map<String, bool>> fetchTransferLogLevel(String protocol) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.SyslogClient.FileTransfer',
        'method': 'get_level',
        'version': '1',
        'protocol': protocol,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '获取日志级别失败' : '获取日志级别失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final levels = data['level'] as Map? ?? const {};
    
    return {
      'create': levels['create'] == '1',
      'write': levels['write'] == '1',
      'move': levels['move'] == '1',
      'delete': levels['delete'] == '1',
      'read': levels['read'] == '1',
      'rename': levels['rename'] == '1',
    };
  }

  /// 设置传输日志级别
  Future<void> setTransferLogLevel(String protocol, Map<String, bool> levels) async {
    final client = _dio;
    
    final levelMap = {
      'create': levels['create'] == true ? '1' : '0',
      'write': levels['write'] == true ? '1' : '0',
      'move': levels['move'] == true ? '1' : '0',
      'delete': levels['delete'] == true ? '1' : '0',
      'read': levels['read'] == true ? '1' : '0',
      'rename': levels['rename'] == true ? '1' : '0',
    };

    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.SyslogClient.FileTransfer',
        'method': 'set_level',
        'version': '1',
        'protocol': protocol,
        'level': jsonEncode(levelMap),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '设置日志级别失败' : '设置日志级别失败');
    }
  }
}
