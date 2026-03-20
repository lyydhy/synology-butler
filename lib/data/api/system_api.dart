import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

    try {
      final infoResponse = await client.get(
        '/webapi/entry.cgi',
        queryParameters: {
          'api': 'SYNO.Core.System',
          'method': 'info',
          'version': '1',
          '_sid': sid,
        },
      );

      final utilizationResponse = await client.get(
        '/webapi/entry.cgi',
        queryParameters: {
          'api': 'SYNO.Core.System.Utilization',
          'method': 'get',
          'version': '1',
          'type': 'current',
          '_sid': sid,
        },
      );

      final infoData = infoResponse.data is Map && infoResponse.data['success'] == true
          ? (infoResponse.data['data'] as Map? ?? const {})
          : const {};
      final utilizationData = utilizationResponse.data is Map && utilizationResponse.data['success'] == true
          ? (utilizationResponse.data['data'] as Map? ?? const {})
          : const {};

      final memory = utilizationData['memory'] as Map? ?? const {};
      final space = utilizationData['space'] as Map? ?? const {};
      final totalSpace = space['total'] as Map? ?? const {};
      final volumeList = (space['volume'] as List?) ?? const [];

      final versionText = _buildVersionText(infoData);

      return SystemStatusModel(
        serverName: (infoData['hostname'] ?? infoData['server_name'] ?? '我的 NAS').toString(),
        dsmVersion: versionText,
        cpuUsage: ((utilizationData['cpu']?['user_load'] as num?) ?? 0).toDouble() +
            ((utilizationData['cpu']?['system_load'] as num?) ?? 0).toDouble() +
            ((utilizationData['cpu']?['other_load'] as num?) ?? 0).toDouble(),
        memoryUsage: ((memory['real_usage'] as num?) ?? 0).toDouble(),
        storageUsage: ((totalSpace['utilization'] as num?) ?? 0).toDouble(),
        volumes: volumeList
            .whereType<Map>()
            .map(
              (item) => StorageVolumeStatusModel(
                name: (item['display_name'] ?? item['device'] ?? 'volume').toString(),
                usage: ((item['utilization'] as num?) ?? 0).toDouble(),
                usedBytes: _toDouble(item['used_size'] ?? item['used']),
                totalBytes: _toDouble(item['total_size'] ?? item['total']),
              ),
            )
            .toList(),
        modelName: (infoData['model'] ?? infoData['modelname'])?.toString(),
        serialNumber: (infoData['serial'] ?? infoData['serial_number'])?.toString(),
        uptimeText: _formatUptime(infoData['uptime'] ?? infoData['uptime_seconds']),
      );
    } catch (e) {
      debugPrint('[HTTP][System][Error] $e');
      rethrow;
    }
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
      final origin = _buildOrigin(baseUrl);
      final pollingState = await _openPollingSession(
        baseUrl: baseUrl,
        synoToken: synoToken,
        cookieHeader: cookieHeader,
        origin: origin,
      );

      final wsUri = _buildWebSocketUri(
        baseUrl: baseUrl,
        engineSid: pollingState.engineSid,
        synoToken: synoToken,
      );

      final headers = <String, dynamic>{
        'Origin': origin,
      };
      final combinedCookie = _mergeCookieHeaders(cookieHeader, pollingState.cookieHeader);
      if (combinedCookie != null && combinedCookie.isNotEmpty) {
        headers['Cookie'] = combinedCookie;
      }

      debugPrint('[WS][Connect] url=$wsUri');
      debugPrint('[WS][Connect] origin=$origin cookie=${combinedCookie == null || combinedCookie.isEmpty ? 'missing' : 'present'} engineSid=${pollingState.engineSid}');

      final socket = await WebSocket.connect(
        wsUri.toString(),
        headers: headers,
      );

      debugPrint('[WS][Connected]');

      int requestIndex = 20;
      bool requested = false;
      Timer? bootstrapTimer;

      void sendFrame(String frame) {
        socket.add(frame);
        debugPrint('[WS][Send] $frame');
      }

      void sendRequestWebApi(String api, int version, String method, Map<String, dynamic> payload) {
        final index = requestIndex++;
        final frame = '42$index${jsonEncode(["request_webapi", api, version, method, payload])}';
        sendFrame(frame);
      }

      void requestCurrent() {
        sendRequestWebApi('SYNO.Core.System.Utilization', 1, 'get', {
          'type': 'current',
          '_sid': sid,
          'SynoToken': synoToken,
        });
        requested = true;
      }

      sendFrame('2probe');
      sendFrame('5');
      sendFrame('40');
      requestCurrent();

      bootstrapTimer = Timer(const Duration(seconds: 2), () {
        debugPrint('[WS][Bootstrap Timeout] no business payload yet, retry request_webapi');
        sendFrame('40');
        requestCurrent();
      });

      controller.onCancel = () async {
        debugPrint('[WS][Closed by client]');
        bootstrapTimer?.cancel();
        await socket.close();
      };

      socket.listen(
        (rawMessage) {
          final text = rawMessage?.toString() ?? '';
          debugPrint('[WS][Frame] $text');

          if (text == '2') {
            sendFrame('3');
            return;
          }

          if (text == '3probe') {
            sendFrame('5');
            return;
          }

          if (text.startsWith('0')) {
            sendFrame('40');
            return;
          }

          if (text == '40') {
            if (!requested) {
              requestCurrent();
            }
            return;
          }

          final payload = _extractRequestWebApiPayload(text);
          if (payload == null || payload['success'] != true) {
            return;
          }

          bootstrapTimer?.cancel();

          final data = payload['data'] as Map? ?? const {};
          final cpu = data['cpu'] as Map? ?? const {};
          final memory = data['memory'] as Map? ?? const {};
          final space = data['space'] as Map? ?? const {};
          final totalSpace = space['total'] as Map? ?? const {};
          final volumeList = (space['volume'] as List?) ?? const [];

          controller.add(
            SystemStatusModel(
              serverName: '我的 NAS',
              dsmVersion: 'DSM 7',
              cpuUsage: ((cpu['user_load'] as num?) ?? 0).toDouble() +
                  ((cpu['system_load'] as num?) ?? 0).toDouble() +
                  ((cpu['other_load'] as num?) ?? 0).toDouble(),
              memoryUsage: ((memory['real_usage'] as num?) ?? 0).toDouble(),
              storageUsage: ((totalSpace['utilization'] as num?) ?? 0).toDouble(),
              volumes: volumeList
                  .whereType<Map>()
                  .map(
                    (item) => StorageVolumeStatusModel(
                      name: (item['display_name'] ?? item['device'] ?? 'volume').toString(),
                      usage: ((item['utilization'] as num?) ?? 0).toDouble(),
                      usedBytes: _toDouble(item['used_size'] ?? item['used']),
                      totalBytes: _toDouble(item['total_size'] ?? item['total']),
                    ),
                  )
                  .toList(),
              uptimeText: null,
            ),
          );
        },
        onError: (error) {
          debugPrint('[WS][Error] $error');
          bootstrapTimer?.cancel();
          controller.addError(error);
        },
        onDone: () {
          debugPrint('[WS][Done]');
          bootstrapTimer?.cancel();
          controller.close();
        },
        cancelOnError: false,
      );
    }).catchError((error) {
      debugPrint('[WS][Connect Error] $error');
      controller.addError(error);
    });

    return controller.stream;
  }

  Future<_PollingState> _openPollingSession({
    required String baseUrl,
    required String synoToken,
    required String origin,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final headers = <String, dynamic>{
      'Origin': origin,
    };
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }

    final uri = _buildPollingUri(baseUrl: baseUrl, synoToken: synoToken);
    debugPrint('[EIO][Polling Open] url=$uri');

    final response = await client.getUri(
      uri,
      options: Options(headers: headers, responseType: ResponseType.plain),
    );

    final raw = response.data?.toString() ?? '';
    debugPrint('[EIO][Polling Open][Response] $raw');

    final engineSid = _extractEngineSid(raw);
    if (engineSid == null || engineSid.isEmpty) {
      throw Exception('Failed to extract engine sid from polling response: $raw');
    }

    final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
    final newCookieHeader = _buildCookieHeader(setCookies);

    return _PollingState(
      engineSid: engineSid,
      cookieHeader: newCookieHeader,
    );
  }

  Uri _buildPollingUri({
    required String baseUrl,
    required String synoToken,
  }) {
    final baseUri = Uri.parse(baseUrl);
    final basePath = baseUri.path == '/' ? '' : baseUri.path;

    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '$basePath/synoscgi.sock/socket.io/',
      queryParameters: {
        'Version': '86009',
        'SynoToken': synoToken,
        'UserType': 'user',
        'EIO': '3',
        'transport': 'polling',
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Uri _buildWebSocketUri({
    required String baseUrl,
    required String engineSid,
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
        'sid': engineSid,
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

  String? _extractEngineSid(String raw) {
    final match = RegExp(r'\{"sid":"([^"]+)"').firstMatch(raw);
    return match?.group(1);
  }

  String? _buildCookieHeader(List<String> setCookies) {
    if (setCookies.isEmpty) return null;

    final pairs = <String>[];
    for (final cookie in setCookies) {
      final firstPart = cookie.split(';').first.trim();
      if (firstPart.isNotEmpty && firstPart.contains('=')) {
        pairs.add(firstPart);
      }
    }

    if (pairs.isEmpty) return null;
    return pairs.join('; ');
  }

  String? _mergeCookieHeaders(String? a, String? b) {
    final parts = <String>[];
    if (a != null && a.isNotEmpty) parts.addAll(a.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    if (b != null && b.isNotEmpty) parts.addAll(b.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    if (parts.isEmpty) return null;

    final cookieMap = <String, String>{};
    for (final part in parts) {
      final idx = part.indexOf('=');
      if (idx <= 0) continue;
      final key = part.substring(0, idx).trim();
      final value = part.substring(idx + 1).trim();
      cookieMap[key] = value;
    }

    return cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Map<String, dynamic>? _extractRequestWebApiPayload(dynamic rawMessage) {
    final text = rawMessage?.toString() ?? '';
    final match = RegExp(r'^43\d+(\[.*\])$').firstMatch(text);
    if (match == null) {
      return null;
    }

    final jsonText = match.group(1)!;
    final decoded = jsonDecode(jsonText);
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    final payload = decoded.first;
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  String _buildVersionText(Map infoData) {
    final versionString = infoData['version_string']?.toString();
    if (versionString != null && versionString.trim().isNotEmpty) {
      return versionString.trim();
    }

    final productVersion = infoData['productversion']?.toString();
    if (productVersion != null && productVersion.trim().isNotEmpty) {
      final build = infoData['buildnumber']?.toString();
      if (build != null && build.trim().isNotEmpty) {
        return 'DSM ${productVersion.trim()}-$build';
      }
      return 'DSM ${productVersion.trim()}';
    }

    final major = infoData['productmajor']?.toString();
    final minor = infoData['productminor']?.toString();
    if (major != null && major.isNotEmpty) {
      return minor != null && minor.isNotEmpty ? 'DSM $major.$minor' : 'DSM $major';
    }

    return 'DSM 版本未知';
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
    if (days > 0) parts.add('${days}天');
    if (hours > 0) parts.add('${hours}小时');
    if (minutes > 0) parts.add('${minutes}分钟');
    if (parts.isEmpty) parts.add('${seconds}秒');
    return parts.join(' ');
  }
}

class _PollingState {
  final String engineSid;
  final String? cookieHeader;

  const _PollingState({
    required this.engineSid,
    this.cookieHeader,
  });
}
