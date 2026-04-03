import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/terminal_settings.dart';

/// 终端（SSH/Telnet）API
class TerminalApi {
  Dio get _dio => businessDio();

  /// 获取终端设置
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
        reason: '获取终端设置异常：$e',
      );
      rethrow;
    }
  }

  /// 设置终端（SSH/Telnet）
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
        reason: '设置终端异常：$e',
      );
      rethrow;
    }
  }
}
