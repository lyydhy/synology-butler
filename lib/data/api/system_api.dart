import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/system_status_model.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview({
    required String baseUrl,
    required String sid,
  });
}

class DsmSystemApi implements SystemApi {
  @override
  Future<SystemStatusModel> fetchOverview({
    required String baseUrl,
    required String sid,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    final infoResponse = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.Core.System',
        'method': 'info',
        'version': '1',
        '_sid': sid,
      },
    );

    if (infoResponse.data is Map && infoResponse.data['success'] == true) {
      final data = infoResponse.data['data'] as Map? ?? const {};

      return SystemStatusModel(
        serverName: (data['hostname'] ?? '我的 NAS').toString(),
        dsmVersion: (data['productversion'] ?? 'DSM 7').toString(),
        cpuUsage: ((data['cpu_usage'] as num?) ?? 0).toDouble(),
        memoryUsage: ((data['memory_usage'] as num?) ?? 0).toDouble(),
        storageUsage: ((data['storage_usage'] as num?) ?? 0).toDouble(),
        modelName: data['model']?.toString(),
        serialNumber: data['serial']?.toString(),
        uptimeText: data['uptime']?.toString(),
      );
    }

    throw DioException(
      requestOptions: infoResponse.requestOptions,
      error: 'Failed to fetch system overview',
      response: infoResponse,
    );
  }
}
