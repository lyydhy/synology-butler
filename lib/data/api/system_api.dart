import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/network/dio_client.dart';
import '../models/system_status_model.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview({
    required String baseUrl,
    required String sid,
  });

  Stream<SystemStatusModel> watchUtilization({
    required String baseUrl,
    required String sid,
    required String synoToken,
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

  @override
  Stream<SystemStatusModel> watchUtilization({
    required String baseUrl,
    required String sid,
    required String synoToken,
  }) {
    final controller = StreamController<SystemStatusModel>();
    final channel = WebSocketChannel.connect(
      _buildSocketUri(
        baseUrl: baseUrl,
        sid: sid,
        synoToken: synoToken,
      ),
    );

    final subscription = channel.stream.listen(
      (rawMessage) {
        final payload = _extractSocketPayload(rawMessage);
        if (payload == null || payload['success'] != true) {
          return;
        }

        final data = payload['data'] as Map? ?? const {};
        final cpu = data['cpu'] as Map? ?? const {};
        final memory = data['memory'] as Map? ?? const {};
        final space = data['space'] as Map? ?? const {};
        final totalSpace = space['total'] as Map? ?? const {};

        controller.add(
          SystemStatusModel(
            serverName: '我的 NAS',
            dsmVersion: 'DSM 7',
            cpuUsage: ((cpu['user_load'] as num?) ?? 0).toDouble() +
                ((cpu['system_load'] as num?) ?? 0).toDouble() +
                ((cpu['other_load'] as num?) ?? 0).toDouble(),
            memoryUsage: ((memory['real_usage'] as num?) ?? 0).toDouble(),
            storageUsage: ((totalSpace['utilization'] as num?) ?? 0).toDouble(),
            uptimeText: null,
          ),
        );
      },
      onError: controller.addError,
      onDone: controller.close,
    );

    controller.onCancel = () async {
      await subscription.cancel();
      await channel.sink.close();
    };

    return controller.stream;
  }

  Uri _buildSocketUri({
    required String baseUrl,
    required String sid,
    required String synoToken,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';

    return Uri(
      scheme: scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '/synoscgi.sock/socket.io/',
      queryParameters: {
        'Version': '86009',
        'SynoToken': synoToken,
        'UserType': 'user',
        'EIO': '3',
        'transport': 'websocket',
        'sid': sid,
      },
    );
  }

  Map<String, dynamic>? _extractSocketPayload(dynamic rawMessage) {
    final text = rawMessage?.toString() ?? '';
    if (!text.startsWith('42[')) {
      return null;
    }

    final jsonText = text.substring(2);
    final decoded = jsonDecode(jsonText);
    if (decoded is! List || decoded.length < 2) {
      return null;
    }

    final eventName = decoded[0]?.toString() ?? '';
    if (eventName != 'SYNO.Core.System.Utilization:1:get') {
      return null;
    }

    final payload = decoded[1];
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }
}
