import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';

class DockerContainerSummary {
  const DockerContainerSummary({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.portsSummary,
  });

  final String id;
  final String name;
  final String image;
  final String status;
  final String portsSummary;
}

class DockerImageSummary {
  const DockerImageSummary({
    required this.id,
    required this.name,
    required this.tag,
    required this.sizeText,
  });

  final String id;
  final String name;
  final String tag;
  final String sizeText;
}

class DockerOverviewData {
  const DockerOverviewData({
    required this.containers,
    required this.images,
  });

  final List<DockerContainerSummary> containers;
  final List<DockerImageSummary> images;
}

class DockerContainerDetail {
  const DockerContainerDetail({
    required this.status,
    required this.command,
    required this.ports,
    required this.volumes,
    required this.envs,
  });

  final String status;
  final String command;
  final List<Map<String, dynamic>> ports;
  final List<Map<String, dynamic>> volumes;
  final List<Map<String, dynamic>> envs;
}

/// 轻量版群晖 Docker 数据源。
///
/// 第一阶段先接入两个最直接的列表：
/// - 容器
/// - 镜像
/// Compose 先保留 UI 骨架，等接口能力再继续补。
class DsmDockerApi {
  Dio get _dio => businessDio(ignoreBadCertificate: connectionStore.server?.ignoreBadCertificate ?? false);

  Options _options() => Options(contentType: Headers.formUrlEncodedContentType);

  String _extractError({required String action, required dynamic data}) {
    return DsmLogger.buildFailureMessage(
      module: 'Docker',
      action: action,
      response: data,
    );
  }

  Future<List<dynamic>> _parallelRequest(List<Map<String, dynamic>> compound, {required String action}) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Entry.Request',
        'method': 'request',
        'mode': 'parallel',
        'compound': jsonEncode(compound),
        'version': '1',
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      return (data['result'] as List?) ?? const [];
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: DsmLogger.buildFailureMessage(
        module: 'Docker',
        action: action,
        response: payload,
      ),
    );
  }

  Future<List<DockerContainerSummary>> fetchContainers() async {
    DsmLogger.request(
      module: 'Docker',
      action: 'fetchContainers',
      method: 'POST',
      path: '/webapi/entry.cgi',
      extra: {'api': 'SYNO.Entry.Request'},
    );

    final result = await _parallelRequest([
      {
        'api': 'SYNO.Docker.Container',
        'method': 'list',
        'version': 1,
        'limit': -1,
        'offset': 0,
        'type': 'all',
      },
      {
        'api': 'SYNO.Docker.Container.Resource',
        'method': 'get',
        'version': 1,
      },
    ], action: 'fetchContainers');

    final containersByName = <String, Map<String, dynamic>>{};
    final resourcesByName = <String, Map<String, dynamic>>{};

    for (final item in result.whereType<Map>()) {
      if (item['success'] != true) continue;
      switch (item['api']) {
        case 'SYNO.Docker.Container':
          final data = item['data'] as Map? ?? const {};
          final containers = (data['containers'] as List?) ?? const [];
          for (final container in containers.whereType<Map>()) {
            final name = (container['name'] ?? '').toString();
            if (name.isNotEmpty) containersByName[name] = Map<String, dynamic>.from(container);
          }
          break;
        case 'SYNO.Docker.Container.Resource':
          final data = item['data'] as Map? ?? const {};
          final resources = (data['resources'] as List?) ?? const [];
          for (final resource in resources.whereType<Map>()) {
            final name = (resource['name'] ?? '').toString();
            if (name.isNotEmpty) resourcesByName[name] = Map<String, dynamic>.from(resource);
          }
          break;
      }
    }

    final containers = containersByName.values.map((container) {
      final name = (container['name'] ?? '').toString();
      final resource = resourcesByName[name] ?? const {};
      final ports = (container['port_settings'] as List?) ?? const [];
      final portsSummary = ports.whereType<Map>().map((port) {
        final host = port['host_port']?.toString();
        final containerPort = port['container_port']?.toString();
        if (host != null && host.isNotEmpty && containerPort != null && containerPort.isNotEmpty) {
          return '$host → $containerPort';
        }
        return containerPort ?? host ?? '';
      }).where((item) => item.isNotEmpty).join('，');

      return DockerContainerSummary(
        id: (container['id'] ?? name).toString(),
        name: name,
        image: (container['image'] ?? '').toString(),
        status: (container['status'] ?? '').toString(),
        portsSummary: portsSummary.isEmpty
            ? ((resource['network'] ?? '').toString().isNotEmpty ? resource['network'].toString() : '未暴露端口')
            : portsSummary,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    DsmLogger.success(
      module: 'Docker',
      action: 'fetchContainers',
      path: '/webapi/entry.cgi',
      response: {'count': containers.length},
    );

    return containers;
  }

  Future<List<DockerImageSummary>> fetchImages() async {
    DsmLogger.request(
      module: 'Docker',
      action: 'fetchImages',
      method: 'POST',
      path: '/webapi/entry.cgi',
      extra: {'api': 'SYNO.Entry.Request'},
    );

    final result = await _parallelRequest([
      {
        'api': 'SYNO.Docker.Image',
        'method': 'list',
        'version': 1,
        'limit': -1,
        'offset': 0,
        'show_dsm': false,
      },
      {
        'api': 'SYNO.Docker.Registry',
        'method': 'get',
        'version': 1,
        'limit': -1,
        'offset': 0,
      },
    ], action: 'fetchImages');

    for (final item in result.whereType<Map>()) {
      if (item['success'] != true || item['api'] != 'SYNO.Docker.Image') continue;
      final data = item['data'] as Map? ?? const {};
      final images = (data['images'] as List?) ?? const [];
      final mapped = images.whereType<Map>().map((image) {
        final repository = (image['repository'] ?? '').toString();
        final tag = (image['tag'] ?? 'latest').toString();
        return DockerImageSummary(
          id: (image['id'] ?? '$repository:$tag').toString(),
          name: repository,
          tag: tag,
          sizeText: (image['size'] ?? image['size_readable'] ?? '--').toString(),
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      DsmLogger.success(
        module: 'Docker',
        action: 'fetchImages',
        path: '/webapi/entry.cgi',
        response: {'count': mapped.length},
      );

      return mapped;
    }

    return const [];
  }

  Future<void> startContainer({required String name}) async {
    await _containerPowerAction(name: name, method: 'start');
  }

  Future<void> stopContainer({required String name}) async {
    await _containerPowerAction(name: name, method: 'stop');
  }

  Future<void> restartContainer({required String name}) async {
    await _containerPowerAction(name: name, method: 'restart');
  }

  Future<void> forceStopContainer({required String name}) async {
    await _containerPowerAction(name: name, method: 'signal', extraData: {'signal': '9'});
  }

  Future<void> _containerPowerAction({
    required String name,
    required String method,
    Map<String, String>? extraData,
  }) async {
    DsmLogger.request(
      module: 'Docker',
      action: method,
      method: 'POST',
      path: '/webapi/entry.cgi',
      extra: {
        'api': 'SYNO.Docker.Container',
        'name': name,
      },
    );

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Container',
        'method': method,
        'version': '1',
        'name': name,
        ...?extraData,
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      DsmLogger.success(
        module: 'Docker',
        action: method,
        path: '/webapi/entry.cgi',
        response: {'name': name},
      );
      return;
    }

    DsmLogger.failure(
      module: 'Docker',
      action: method,
      path: '/webapi/entry.cgi',
      response: payload,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: method, data: payload),
    );
  }

  Future<DockerContainerDetail> fetchContainerDetail({required String name}) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Container',
        'method': 'get',
        'version': '1',
        'name': name,
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      final profile = data['profile'] as Map? ?? const {};
      final details = data['details'] as Map? ?? const {};
      return DockerContainerDetail(
        status: (details['status'] ?? '').toString(),
        command: (details['exe_cmd'] ?? '').toString(),
        ports: ((profile['port_bindings'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
        volumes: ((profile['volume_bindings'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
        envs: ((profile['env_variables'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'fetchContainerDetail', data: payload),
    );
  }

  Future<List<String>> fetchContainerLogDates({required String name}) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Container.Log',
        'method': 'get_date_list',
        'version': '1',
        'name': name,
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      return ((data['dates'] as List?) ?? const []).map((e) => e.toString()).toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'fetchContainerLogDates', data: payload),
    );
  }

  Future<List<String>> fetchContainerLogs({
    required String name,
    required String date,
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Container.Log',
        'method': 'get',
        'version': '1',
        'name': name,
        'sort_dir': 'ASC',
        'date': date,
        'limit': '1000',
        'offset': '0',
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      return ((data['logs'] as List?) ?? const []).map((e) => e.toString()).toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'fetchContainerLogs', data: payload),
    );
  }

  Future<DockerOverviewData> fetchOverview() async {
    final containers = await fetchContainers();
    final images = await fetchImages();
    return DockerOverviewData(containers: containers, images: images);
  }
}
