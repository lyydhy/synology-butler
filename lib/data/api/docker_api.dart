import 'dart:async';
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

class DockerComposeProjectSummary {
  const DockerComposeProjectSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.state,
    required this.path,
    required this.containerIds,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String status;
  final String state;
  final String path;
  final List<String> containerIds;
  final String updatedAt;
}

class DockerOverviewData {
  const DockerOverviewData({
    required this.containers,
    required this.images,
    required this.projects,
  });

  final List<DockerContainerSummary> containers;
  final List<DockerImageSummary> images;
  final List<DockerComposeProjectSummary> projects;
}

class DockerContainerDetail {
  const DockerContainerDetail({
    required this.status,
    required this.command,
    required this.ports,
    required this.volumes,
    required this.envs,
    required this.processes,
  });

  final String status;
  final String command;
  final List<Map<String, dynamic>> ports;
  final List<Map<String, dynamic>> volumes;
  final List<Map<String, dynamic>> envs;
  final List<List<String>> processes;
}

class DockerComposeProjectDetail {
  const DockerComposeProjectDetail({
    required this.id,
    required this.name,
    required this.path,
    required this.sharePath,
    required this.status,
    required this.state,
    required this.updatedAt,
    required this.content,
    required this.containers,
    required this.containerIds,
  });

  final String id;
  final String name;
  final String path;
  final String sharePath;
  final String status;
  final String state;
  final String updatedAt;
  final String content;
  final List<Map<String, dynamic>> containers;
  final List<String> containerIds;
}

class DockerComposeCreateRequest {
  const DockerComposeCreateRequest({
    required this.name,
    required this.sharePath,
    required this.content,
    this.enableServicePortal = false,
    this.servicePortalName = '',
    this.servicePortalPort = 0,
    this.servicePortalProtocol = '',
  });

  final String name;
  final String sharePath;
  final String content;
  final bool enableServicePortal;
  final String servicePortalName;
  final int servicePortalPort;
  final String servicePortalProtocol;
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

  Future<List<DockerComposeProjectSummary>> fetchProjects() async {
    DsmLogger.request(
      module: 'Docker',
      action: 'fetchProjects',
      method: 'POST',
      path: '/webapi/entry.cgi',
      extra: {'api': 'SYNO.Docker.Project'},
    );

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Project',
        'method': 'list',
        'version': '1',
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      final projects = data.values.whereType<Map>().map((item) {
        return DockerComposeProjectSummary(
          id: (item['id'] ?? '').toString(),
          name: (item['name'] ?? '').toString(),
          status: (item['status'] ?? '').toString(),
          state: (item['state'] ?? '').toString(),
          path: (item['path'] ?? item['share_path'] ?? '').toString(),
          containerIds: ((item['containerIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
          updatedAt: (item['updated_at'] ?? '').toString(),
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      DsmLogger.success(
        module: 'Docker',
        action: 'fetchProjects',
        path: '/webapi/entry.cgi',
        response: {'count': projects.length},
      );

      return projects;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'fetchProjects', data: payload),
    );
  }

  Future<DockerComposeProjectDetail> fetchProjectDetail({required String id}) async {
    DsmLogger.request(
      module: 'Docker',
      action: 'fetchProjectDetail',
      method: 'POST',
      path: '/webapi/entry.cgi',
      extra: {
        'api': 'SYNO.Docker.Project',
        'id': id,
      },
    );

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Project',
        'method': 'get',
        'version': '1',
        'id': id,
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      return DockerComposeProjectDetail(
        id: (data['id'] ?? '').toString(),
        name: (data['name'] ?? '').toString(),
        path: (data['path'] ?? '').toString(),
        sharePath: (data['share_path'] ?? '').toString(),
        status: (data['status'] ?? '').toString(),
        state: (data['state'] ?? '').toString(),
        updatedAt: (data['updated_at'] ?? '').toString(),
        content: (data['content'] ?? '').toString(),
        containers: ((data['containers'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        containerIds: ((data['containerIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'fetchProjectDetail', data: payload),
    );
  }

  Future<DockerComposeProjectDetail> createProject(DockerComposeCreateRequest request) async {
    DsmLogger.request(
      module: 'Docker',
      action: 'createProject',
      method: 'POST',
      path: '/webapi/entry.cgi/SYNO.Docker.Project',
      extra: {
        'api': 'SYNO.Docker.Project',
        'name': request.name,
        'share_path': request.sharePath,
      },
    );

    final response = await _dio.post(
      '/webapi/entry.cgi/SYNO.Docker.Project',
      data: {
        'api': 'SYNO.Docker.Project',
        'method': 'create',
        'version': '1',
        'name': request.name,
        'content': request.content,
        'share_path': request.sharePath,
        'enable_service_portal': request.enableServicePortal,
        'service_portal_name': request.servicePortalName,
        'service_portal_port': request.servicePortalPort,
        'service_portal_protocol': request.servicePortalProtocol,
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      return DockerComposeProjectDetail(
        id: (data['id'] ?? '').toString(),
        name: (data['name'] ?? '').toString(),
        path: (data['path'] ?? '').toString(),
        sharePath: (data['share_path'] ?? '').toString(),
        status: (data['status'] ?? '').toString(),
        state: (data['state'] ?? '').toString(),
        updatedAt: (data['updated_at'] ?? '').toString(),
        content: (data['content'] ?? '').toString(),
        containers: ((data['containers'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        containerIds: ((data['containerIds'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'createProject', data: payload),
    );
  }

  Stream<String> buildProjectStream({required String id}) {
    return _projectActionStream(id: id, method: 'build_stream', action: 'buildProjectStream', errorLabel: '构建日志');
  }

  Stream<String> startProjectStream({required String id}) {
    return _projectActionStream(id: id, method: 'start_stream', action: 'startProjectStream', errorLabel: '启动日志');
  }

  Stream<String> stopProjectStream({required String id}) {
    return _projectActionStream(id: id, method: 'stop_stream', action: 'stopProjectStream', errorLabel: '停止日志');
  }

  Stream<String> restartProjectStream({required String id}) {
    return _projectActionStream(id: id, method: 'restart_stream', action: 'restartProjectStream', errorLabel: '重启日志');
  }

  Stream<String> cleanProjectStream({required String id}) {
    return _projectActionStream(id: id, method: 'clean_stream', action: 'cleanProjectStream', errorLabel: '清除日志');
  }

  Future<void> deleteProject({required String id}) async {
    DsmLogger.request(
      module: 'Docker',
      action: 'deleteProject',
      method: 'POST',
      path: '/webapi/entry.cgi/SYNO.Docker.Project',
      extra: {
        'api': 'SYNO.Docker.Project',
        'id': id,
      },
    );

    final response = await _dio.post(
      '/webapi/entry.cgi/SYNO.Docker.Project',
      data: {
        'api': 'SYNO.Docker.Project',
        'method': 'delete',
        'version': '1',
        'id': id,
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      DsmLogger.success(
        module: 'Docker',
        action: 'deleteProject',
        path: '/webapi/entry.cgi/SYNO.Docker.Project',
        response: {'id': id},
      );
      return;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'deleteProject', data: payload),
    );
  }

  Stream<String> _projectActionStream({
    required String id,
    required String method,
    required String action,
    required String errorLabel,
  }) async* {
    DsmLogger.request(
      module: 'Docker',
      action: action,
      method: 'POST',
      path: '/webapi/entry.cgi/SYNO.Docker.Project',
      extra: {
        'api': 'SYNO.Docker.Project',
        'id': id,
        'method': method,
      },
    );

    final response = await _dio.post<ResponseBody>(
      '/webapi/entry.cgi/SYNO.Docker.Project',
      data: {
        'api': 'SYNO.Docker.Project',
        'method': method,
        'version': '1',
        'id': id,
      },
      options: _options().copyWith(responseType: ResponseType.stream),
    );

    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: '未收到$errorLabel',
      );
    }

    final stream = body.stream.map((chunk) => utf8.decode(chunk)).asBroadcastStream();
    await for (final chunk in stream) {
      if (chunk.isNotEmpty) {
        yield chunk;
      }
    }
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
    final detailResponse = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Container',
        'method': 'get',
        'version': '1',
        'name': name,
      },
      options: _options(),
    );

    final detailPayload = detailResponse.data;
    if (!(detailPayload is Map && detailPayload['success'] == true)) {
      throw DioException(
        requestOptions: detailResponse.requestOptions,
        response: detailResponse,
        error: _extractError(action: 'fetchContainerDetail', data: detailPayload),
      );
    }

    final processResponse = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Docker.Container',
        'method': 'get_process',
        'version': '1',
        'name': name,
      },
      options: _options(),
    );

    final processPayload = processResponse.data;
    final detailData = detailPayload['data'] as Map? ?? const {};
    final profile = detailData['profile'] as Map? ?? const {};
    final details = detailData['details'] as Map? ?? const {};
    final processData = processPayload is Map && processPayload['success'] == true ? (processPayload['data'] as Map? ?? const {}) : const {};

    return DockerContainerDetail(
      status: (details['status'] ?? '').toString(),
      command: (details['exe_cmd'] ?? '').toString(),
      ports: ((profile['port_bindings'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      volumes: ((profile['volume_bindings'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      envs: ((profile['env_variables'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      processes: ((processData['processes'] as List?) ?? const [])
          .whereType<List>()
          .map((row) => row.map((item) => item.toString()).toList())
          .toList(),
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

  Future<String> fetchContainerLogs({
    required String name,
    required String date,
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi/SYNO.Docker.Container.Log',
      data: {
        'api': 'SYNO.Docker.Container.Log',
        'method': 'get',
        'version': '1',
        'name': name,
        'from': '',
        'to': '',
        'level': '',
        'keyword': '',
        'sort_dir': 'DESC',
        'offset': '0',
        'limit': '1000',
      },
      options: _options(),
    );

    final payload = response.data;
    if (payload is Map && payload['success'] == true) {
      final data = payload['data'] as Map? ?? const {};
      final logs = ((data['logs'] as List?) ?? const []).whereType<Map>().map((item) {
        final created = (item['created'] ?? '').toString();
        final stream = (item['stream'] ?? '').toString();
        final text = _stripAnsi((item['text'] ?? '').toString()).trimRight();

        final prefix = [
          if (created.isNotEmpty) created,
          if (stream.isNotEmpty) stream,
        ].join(' | ');

        if (prefix.isEmpty) return text;
        if (text.isEmpty) return prefix;
        return '[$prefix] $text';
      }).where((line) => line.trim().isNotEmpty).toList();

      return logs.join('\n');
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: _extractError(action: 'fetchContainerLogs', data: payload),
    );
  }

  String _stripAnsi(String input) {
    final ansiRegex = RegExp(r'\x1B\[[0-9;]*[A-Za-z]');
    return input.replaceAll(ansiRegex, '');
  }

  Future<DockerOverviewData> fetchOverview() async {
    final containers = await fetchContainers();
    final images = await fetchImages();
    final projects = await fetchProjects();
    return DockerOverviewData(
      containers: containers,
      images: images,
      projects: projects,
    );
  }
}
