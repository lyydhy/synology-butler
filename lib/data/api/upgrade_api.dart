import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/upgrade_status.dart';

/// DSM 升级 API
class UpgradeApi {
  Dio get _dio => businessDio();

  /// 检查 DSM 更新
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
        reason: '检查更新异常：$e',
      );
      rethrow;
    }
  }
}
