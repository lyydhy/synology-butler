import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

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
    String? cookieHeader,
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
    String? cookieHeader,
  }) {
    final controller = StreamController<SystemStatusModel>();

    Future<void>(() async {
      final uri = _buildSocketUri(
        baseUrl: baseUrl,
        sid: sid,
        synoToken: synoToken,
      );
      final origin = _buildOrigin(baseUrl);

      final headers = <String, dynamic>{
        'Origin': origin,
      };
      if (cookieHeader != null && cookieHeader.isNotEmpty) {
        headers['Cookie'] = cookieHeader;
      }

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: headers,
      );

      controller.onCancel = () async {
        await socket.close();
      };

      socket.listen(
        (rawMessage) {
          final text = rawMessage?.toString() ?? '';

          if (text.startsWith('0')) {
            socket.add('40');
            return;
          }

          if (text == '40') {
            socket.add('42["SYNO.Core.System.Utilization:1:get",{}]');
            return;
          }

          if (text == '2') {
            socket.add('3');
            return;
          }

          final payload = _extractSocketPayload(text);
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
        cancelOnError: false,
      );
    }).catchError(controller.addError);

    return controller.stream;
  }

  Uri _buildSocketUri({
    required String baseUrl,
    required String sid,
    required String synoToken,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final basePath = baseUri.path == '/' ? '' : baseUri.path;

    return Uri(
      scheme: scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '$basePath/synoscgi.sock/socket.io/',
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

  String _buildOrigin(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final host = uri.host;
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$portPart';
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
