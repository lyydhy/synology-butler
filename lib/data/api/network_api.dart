import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/network.dart';

/// 网络 API
class NetworkApi {
  Dio get _dio => businessDio();

  /// 获取网络状态
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
        reason: '获取网络状态异常：$e',
      );
      rethrow;
    }
  }
}
