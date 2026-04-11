import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/system_status_model.dart';

class _PollingState {
  _PollingState({required this.engineSid, required this.cookieHeader});
  final String engineSid;
  final String cookieHeader;
}

abstract class RealtimeApi {
  Stream<SystemStatusModel> watchUtilization();
}

class DsmRealtimeApi implements RealtimeApi {
  DsmRealtimeApi({bool ignoreBadCertificate = false});

  String get _baseUrl {
    final server = connectionStore.server;
    if (server == null) return '';
    final scheme = server.https ? 'https' : 'http';
    final host = server.host
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/$'), '');
    final basePath =
        (server.basePath == null || server.basePath!.trim().isEmpty)
            ? ''
            : (server.basePath!.startsWith('/')
                ? server.basePath!
                : '/${server.basePath!}');
    return '$scheme://$host:${server.port}$basePath';
  }

  String get _sid => connectionStore.session?.sid ?? '';

  String? get _synoToken => connectionStore.session?.synoToken;

  String? get _cookieHeader => connectionStore.session?.cookieHeader;

  @override
  Stream<SystemStatusModel> watchUtilization() {
    final synoToken = _synoToken;
    final cookieHeader = _cookieHeader;
    if (synoToken == null || synoToken.isEmpty) {
      throw Exception('Missing SynoToken for realtime utilization');
    }
    final baseUrl = _baseUrl;
    final controller = StreamController<SystemStatusModel>();

    DsmLogger.request(
      module: 'System',
      action: 'watchUtilization',
      method: 'WS',
      path: _baseUrl,
      sid: _sid,
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
      final combinedCookie =
          _mergeCookieHeaders(cookieHeader, pollingState.cookieHeader);
      if (combinedCookie != null && combinedCookie.isNotEmpty) {
        headers['Cookie'] = combinedCookie;
      }

      debugPrint('[WS][Connect] url=$wsUri');
      debugPrint(
          '[WS][Connect] origin=$origin cookie=${combinedCookie == null || combinedCookie.isEmpty ? 'missing' : 'present'} engineSid=${pollingState.engineSid}');

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

      void sendRequestWebApi(String api, int version, String method,
          Map<String, dynamic> payload) {
        final index = requestIndex++;
        final frame = '42$index${jsonEncode([
              "request_webapi",
              api,
              version,
              method,
              payload
            ])}';
        sendFrame(frame);
      }

      void requestCurrent() {
        sendRequestWebApi('SYNO.Core.System.Utilization', 1, 'get', {
          'type': 'current',
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
          path: _baseUrl,
          reason: 'Realtime authentication error: $reason',
          sid: _sid,
          synoToken: synoToken,
          cookieHeader: cookieHeader,
        );
        controller
            .addError(Exception('Realtime authentication error: $reason'));
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
          path: _baseUrl,
          reason:
              'Realtime bootstrap timeout after websocket connect; auth likely expired',
          sid: _sid,
          synoToken: synoToken,
          cookieHeader: cookieHeader,
        );
        controller.addError(Exception(
            'Realtime bootstrap timeout after websocket connect; auth likely expired'));
        socket.close();
      }

      sendFrame('2probe');
      sendFrame('5');
      sendFrame('40');
      requestCurrent();

      bootstrapTimer = Timer(const Duration(seconds: 2), failBootstrapTimeout);
      Timer? periodicTimer;

      void startPeriodicTimer() {
        periodicTimer?.cancel();
        periodicTimer = Timer.periodic(
          const Duration(seconds: AppConstants.realtimeRequestIntervalSeconds),
          (_) => requestCurrent(),
        );
      }

      controller.onCancel = () async {
        debugPrint('[WS][Closed by client]');
        bootstrapTimer?.cancel();
        periodicTimer?.cancel();
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
          startPeriodicTimer();

          final data = payload['data'] as Map? ?? const {};
          final spacePreview = data['space'];
          DsmLogger.success(
            module: 'System',
            action: 'watchUtilization',
            path: _baseUrl,
            response: {
              'received': true,
              'spaceKeys': spacePreview is Map
                  ? spacePreview.keys.map((e) => e.toString()).toList()
                  : [],
            },
          );

          final cpu = data['cpu'] as Map? ?? const {};
          final memory = data['memory'] as Map? ?? const {};
          final network = data['network'] as List? ?? const [];
          final disk = data['disk'] as Map? ?? const {};
          final networkTotals = _extractNetworkTotals(network);
          final networkInterfaces = _extractNetworkInterfaces(network);
          final diskTotals = _extractDiskTotals(disk);
          final disks = _extractDiskStatuses(disk);
          final space = data['space'] as Map? ?? const {};
          final totalSpace = space['total'] as Map? ?? const {};
          final volumeList = _extractVolumeList(space);
          final volumePerformances = _extractVolumePerformanceStatuses(space);
          final mappedVolumes = volumeList
              .whereType<Map>()
              .map(
                (item) => StorageVolumeStatusModel(
                  name: (item['display_name'] ??
                          item['device'] ??
                          item['name'] ??
                          'volume')
                      .toString(),
                  usage: ((item['utilization'] as num?) ?? 0).toDouble(),
                  usedBytes: _toDouble(
                    item['used_size'] ??
                        item['used'] ??
                        item['volume_status']?['used_size'] ??
                        item['volume_status']?['used'],
                  ),
                  totalBytes: _toDouble(
                    item['total_size'] ??
                        item['total'] ??
                        item['volume_status']?['totalspace'] ??
                        item['volume_status']?['total'],
                  ),
                ),
              )
              .toList();

          DsmLogger.success(
            module: 'System',
            action: 'watchUtilizationVolumes',
            path: _baseUrl,
            response: {
              'count': mappedVolumes.length,
              'names': mappedVolumes.map((e) => e.name).toList(),
            },
          );

          controller.add(
            SystemStatusModel(
              serverName: '我的 NAS',
              dsmVersion: 'DSM 7',
              cpuUsage: ((cpu['user_load'] as num?) ?? 0).toDouble() +
                  ((cpu['system_load'] as num?) ?? 0).toDouble() +
                  ((cpu['other_load'] as num?) ?? 0).toDouble(),
              cpuUserUsage: ((cpu['user_load'] as num?) ?? 0).toDouble(),
              cpuSystemUsage: ((cpu['system_load'] as num?) ?? 0).toDouble(),
              cpuIoWaitUsage: ((cpu['other_load'] as num?) ?? 0).toDouble(),
              load1: (((cpu['1min_load'] as num?) ?? 0).toDouble()) / 100,
              load5: (((cpu['5min_load'] as num?) ?? 0).toDouble()) / 100,
              load15: (((cpu['15min_load'] as num?) ?? 0).toDouble()) / 100,
              memoryUsage: ((memory['real_usage'] as num?) ?? 0).toDouble(),
              memoryTotalBytes:
                  _toDouble(memory['total'] ?? memory['totalspace']),
              memoryUsedBytes: _toDouble(memory['used']),
              memoryBufferBytes: _toDouble(memory['buffer']),
              memoryCachedBytes: _toDouble(memory['cached']),
              memoryAvailableBytes:
                  _toDouble(memory['available'] ?? memory['avail']),
              storageUsage: ((totalSpace['used_percent'] as num?) ?? 0)
                  .toDouble(),
              networkUploadBytesPerSecond:
                  _toDouble(networkTotals['tx_bytes_per_second']),
              networkDownloadBytesPerSecond:
                  _toDouble(networkTotals['rx_bytes_per_second']),
              diskReadBytesPerSecond:
                  _toDouble(diskTotals['read_bytes_per_second']),
              diskWriteBytesPerSecond:
                  _toDouble(diskTotals['write_bytes_per_second']),
              networkInterfaces: networkInterfaces,
              disks: disks,
              volumePerformances: volumePerformances,
              volumes: mappedVolumes,
              modelName: 'DSM',
              serialNumber: '',
              uptimeText: '',
            ),
          );
        },
        onError: (error) {
          debugPrint('[WS][Error] $error');
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
        onDone: () {
          debugPrint('[WS][Done]');
          if (!controller.isClosed) {
            controller.close();
          }
        },
        cancelOnError: false,
      );
    }).catchError((error, stackTrace) {
      debugPrint('[WS][Setup Error] $error');
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
        controller.close();
      }
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

    final engineSid = _extractEngineSid(raw) ?? '';
    if (engineSid.isEmpty) {
      throw Exception(
          'Failed to extract engine sid from polling response: $raw');
    }

    final setCookies = response.headers.map['set-cookie'] ?? const <String>[];
    final newCookieHeader = _buildCookieHeader(setCookies) ?? '';

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
    if (a != null && a.isNotEmpty) {
      parts.addAll(a.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (b != null && b.isNotEmpty) {
      parts.addAll(b.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
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

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> _extractNetworkTotals(List network) {
    int tx = 0;
    int rx = 0;
    for (final item in network) {
      if (item is Map) {
        tx += (item['tx_bytes_per_second'] as num?)?.toInt() ?? 0;
        rx += (item['rx_bytes_per_second'] as num?)?.toInt() ?? 0;
      }
    }
    return {'tx_bytes_per_second': tx, 'rx_bytes_per_second': rx};
  }

  List<NetworkInterfaceStatusModel> _extractNetworkInterfaces(List network) {
    return network
        .whereType<Map>()
        .map(
          (item) => NetworkInterfaceStatusModel(
            name: (item['name'] ?? '').toString(),
            uploadBytesPerSecond:
                ((item['tx_bytes_per_second'] as num?) ?? 0).toDouble(),
            downloadBytesPerSecond:
                ((item['rx_bytes_per_second'] as num?) ?? 0).toDouble(),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _extractDiskTotals(Map disk) {
    // Try total aggregate first (DSM 7 primary)
    final total = disk['total'] as Map?;
    if (total != null) {
      return {
        'read_bytes_per_second': _toDouble(total['read_byte']) ?? 0,
        'write_bytes_per_second': _toDouble(total['write_byte']) ?? 0,
      };
    }
    // Fallback: sum from individual disks
    int read = 0;
    int write = 0;
    final diskList = disk['disk'] as List? ?? (disk['disks'] as List?) ?? const [];
    for (final item in diskList) {
      if (item is Map) {
        read += (item['read_bytes_per_second'] as num?)?.toInt() ?? 0;
        write += (item['write_bytes_per_second'] as num?)?.toInt() ?? 0;
      }
    }
    return {
      'read_bytes_per_second': read.toDouble(),
      'write_bytes_per_second': write.toDouble(),
    };
  }

  List<DiskStatusModel> _extractDiskStatuses(Map disk) {
    // Try device list first (DSM 7)
    List items = disk['disk'] as List? ?? (disk['disks'] as List?) ?? (disk['device'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map(
          (item) => DiskStatusModel(
            name: (item['display_name'] ?? item['name'] ?? item['device'] ?? item['diskno'] ?? '').toString(),
            utilization: _toDouble(item['utilization']) ?? 0,
            readBytesPerSecond:
                _toDouble(item['read_byte'] ?? item['read_bytes_per_second']) ?? 0,
            writeBytesPerSecond:
                _toDouble(item['write_byte'] ?? item['write_bytes_per_second']) ?? 0,
            readIops: _toDouble(item['read_access'] ?? item['read_iops']) ?? 0,
            writeIops: _toDouble(item['write_access'] ?? item['write_iops']) ?? 0,
          ),
        )
        .toList();
  }

  List<VolumePerformanceStatusModel> _extractVolumePerformanceStatuses(
      Map space) {
    final volumeList = space['volume'] as List? ?? const [];
    return volumeList
        .whereType<Map>()
        .map(
          (item) => VolumePerformanceStatusModel(
            name: (item['display_name'] ?? item['device'] ?? '').toString(),
            utilization: ((item['utilization'] as num?) ?? 0).toDouble(),
            readBytesPerSecond:
                ((item['read_bytes_per_second'] as num?) ?? 0).toDouble(),
            writeBytesPerSecond:
                ((item['write_bytes_per_second'] as num?) ?? 0).toDouble(),
            readIops: ((item['read_iops'] as num?) ?? 0).toDouble(),
            writeIops: ((item['write_iops'] as num?) ?? 0).toDouble(),
          ),
        )
        .toList();
  }

  List<Map> _extractVolumeList(Map space) {
    return (space['volume'] as List? ?? const [])
        .whereType<Map>()
        .toList();
  }
}
