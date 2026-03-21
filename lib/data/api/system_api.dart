import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/system_status_model.dart';

abstract class SystemApi {
  Future<SystemStatusModel> fetchOverview({
    required String baseUrl,
    required String sid,
    String? synoToken,
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
    String? synoToken,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'System',
      action: 'fetchOverview',
      method: 'GET',
      path: baseUrl,
      sid: sid,
      synoToken: synoToken,
      extra: {
        'apis': [
          'SYNO.Core.System',
          'SYNO.Core.System.Utilization',
          'SYNO.Entry.Request/SYNO.Core.Upgrade.Server.check',
          'SYNO.Core.System.SystemHealth',
        ],
      },
    );

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
      final volumeList = _extractVolumeList(space);

      final upgradeVersionText = await _fetchUpgradeVersion(
        client: client,
        sid: sid,
        synoToken: synoToken,
      );
      final systemHealthUptime = await _fetchSystemHealthUptime(
        client: client,
        sid: sid,
        synoToken: synoToken,
      );
      final versionText = upgradeVersionText ?? _buildVersionText(infoData);

      final result = SystemStatusModel(
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
        uptimeText: systemHealthUptime ?? _formatUptime(infoData['uptime'] ?? infoData['uptime_seconds']),
      );

      DsmLogger.success(
        module: 'System',
        action: 'fetchOverview',
        path: baseUrl,
        response: {
          'serverName': result.serverName,
          'dsmVersion': result.dsmVersion,
          'volumes': result.volumes.length,
          'uptimeText': result.uptimeText,
        },
      );

      return result;
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchOverview',
        path: baseUrl,
        reason: e.toString(),
        sid: sid,
        synoToken: synoToken,
      );
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

    DsmLogger.request(
      module: 'System',
      action: 'watchUtilization',
      method: 'WS',
      path: baseUrl,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.Core.System.Utilization',
        'type': 'current',
      },
    );

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
      bool terminalStateReached = false;
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

      void failAuth(String reason) {
        if (terminalStateReached || controller.isClosed) {
          return;
        }
        terminalStateReached = true;
        bootstrapTimer?.cancel();
        DsmLogger.failure(
          module: 'System',
          action: 'watchUtilization',
          path: baseUrl,
          reason: 'Realtime authentication error: $reason',
          sid: sid,
          synoToken: synoToken,
          cookieHeader: cookieHeader,
        );
        controller.addError(Exception('Realtime authentication error: $reason'));
        socket.close();
      }

      void failBootstrapTimeout() {
        if (terminalStateReached || controller.isClosed) {
          return;
        }
        terminalStateReached = true;
        bootstrapTimer?.cancel();
        DsmLogger.failure(
          module: 'System',
          action: 'watchUtilization',
          path: baseUrl,
          reason: 'Realtime bootstrap timeout after websocket connect; auth likely expired',
          sid: sid,
          synoToken: synoToken,
          cookieHeader: cookieHeader,
        );
        controller.addError(Exception('Realtime bootstrap timeout after websocket connect; auth likely expired'));
        socket.close();
      }

      sendFrame('2probe');
      sendFrame('5');
      sendFrame('40');
      requestCurrent();

      bootstrapTimer = Timer(const Duration(seconds: 2), failBootstrapTimeout);

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

          if (_isAuthenticationErrorFrame(text)) {
            failAuth(text);
            return;
          }

          final payload = _extractRequestWebApiPayload(text);
          if (payload == null) {
            return;
          }

          if (payload['success'] != true) {
            if (_payloadLooksLikeAuthFailure(payload)) {
              failAuth(jsonEncode(payload));
            }
            return;
          }

          terminalStateReached = true;
          bootstrapTimer?.cancel();

          DsmLogger.success(
            module: 'System',
            action: 'watchUtilization',
            path: baseUrl,
            response: {
              'received': true,
            },
          );

          final data = payload['data'] as Map? ?? const {};
          final cpu = data['cpu'] as Map? ?? const {};
          final memory = data['memory'] as Map? ?? const {};
          final space = data['space'] as Map? ?? const {};
          final totalSpace = space['total'] as Map? ?? const {};
          final volumeList = _extractVolumeList(space);

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

  bool _isAuthenticationErrorFrame(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('authentication error') ||
        normalized.contains('invalid sid') ||
        normalized.contains('unauthorized');
  }

  bool _payloadLooksLikeAuthFailure(Map<String, dynamic> payload) {
    final code = payload['code']?.toString();
    final errors = payload['errors'];
    final text = jsonEncode(payload).toLowerCase();

    if (code == '119') {
      return true;
    }

    if (errors is Map) {
      final errorCode = errors['code']?.toString();
      if (errorCode == '119') {
        return true;
      }
    }

    return text.contains('authentication error') ||
        text.contains('invalid sid') ||
        text.contains('synotoken') ||
        text.contains('unauthorized') ||
        text.contains('auth');
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

  Future<String?> _fetchUpgradeVersion({
    required Dio client,
    required String sid,
    String? synoToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (synoToken != null && synoToken.isNotEmpty) {
        headers['X-SYNO-TOKEN'] = synoToken;
      }

      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Entry.Request',
          'method': 'request',
          'version': '1',
          'stop_when_error': 'false',
          'mode': 'sequential',
          'compound': jsonEncode([
            {
              'api': 'SYNO.Core.Upgrade.Server',
              'method': 'check',
              'version': 1,
              'need_auto_smallupdate': true,
            },
          ]),
          '_sid': sid,
        },
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) return null;

      final result = data['data']?['result'];
      if (result is! List) return null;

      for (final item in result.whereType<Map>()) {
        if (item['api']?.toString() != 'SYNO.Core.Upgrade.Server') continue;
        if (item['success'] != true) continue;

        final payload = item['data'] as Map? ?? const {};
        final version = payload['version']?.toString();
        if (version != null && version.trim().isNotEmpty) {
          return version.trim();
        }

        final details = payload['version_details'] as Map? ?? const {};
        final osName = details['os_name']?.toString() ?? 'DSM';
        final major = details['major']?.toString();
        final minor = details['minor']?.toString();
        final micro = details['micro']?.toString();
        final nano = details['nano']?.toString();
        final build = details['buildnumber']?.toString();

        final parts = <String>[];
        if (major != null && major.isNotEmpty) {
          var versionNumber = major;
          if (minor != null && minor.isNotEmpty) versionNumber += '.$minor';
          if (micro != null && micro.isNotEmpty) versionNumber += '.$micro';
          if (nano != null && nano.isNotEmpty && nano != '0') versionNumber += ' Update $nano';
          parts.add('$osName $versionNumber');
        }
        if (build != null && build.isNotEmpty) {
          if (parts.isEmpty) {
            parts.add('$osName $build');
          } else {
            parts[0] = parts[0].replaceFirst(' Update', '-$build Update');
            if (!parts[0].contains('-$build')) {
              parts[0] = '${parts[0]}-$build';
            }
          }
        }

        if (parts.isNotEmpty) {
          return parts.first.trim();
        }
      }
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchUpgradeVersion',
        reason: e.toString(),
        sid: sid,
        synoToken: synoToken,
      );
    }

    return null;
  }

  Future<String?> _fetchSystemHealthUptime({
    required Dio client,
    required String sid,
    String? synoToken,
  }) async {
    try {
      final headers = <String, dynamic>{};
      if (synoToken != null && synoToken.isNotEmpty) {
        headers['X-SYNO-TOKEN'] = synoToken;
      }

      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.System.SystemHealth',
          'method': 'get',
          'version': '1',
          '_sid': sid,
        },
        options: Options(headers: headers),
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      final payload = data['data'] as Map? ?? const {};
      final uptime = payload['uptime']?.toString();
      if (uptime == null || uptime.trim().isEmpty) return null;
      return uptime.trim();
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'fetchSystemHealthUptime',
        reason: e.toString(),
        sid: sid,
        synoToken: synoToken,
      );
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

  List<Map> _extractVolumeList(Map space) {
    final direct = space['volume'];
    if (direct is List) {
      return direct.whereType<Map>().toList();
    }

    final volumes = space['volumes'];
    if (volumes is List) {
      return volumes.whereType<Map>().toList();
    }

    final items = space['items'];
    if (items is List) {
      return items.whereType<Map>().where((item) {
        final name = (item['display_name'] ?? item['device'] ?? item['name'] ?? '').toString().toLowerCase();
        return name.startsWith('volume');
      }).toList();
    }

    return const [];
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
