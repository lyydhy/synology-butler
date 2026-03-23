import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/file_item_model.dart';

abstract class FileStationApi {
  Future<List<FileItemModel>> listFiles({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  });

  Future<Uint8List> downloadFile({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
    void Function(int received, int total)? onReceiveProgress,
  });

  Future<String> readTextFile({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> writeTextFile({
    required String baseUrl,
    required String sid,
    required String path,
    required String content,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> createFolder({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String name,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> rename({
    required String baseUrl,
    required String sid,
    required String path,
    required String newName,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> delete({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  });

  Future<String> createShareLink({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  });

  Future<void> uploadFile({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
    String? synoToken,
    String? cookieHeader,
  });
}

class DsmFileStationApi implements FileStationApi {
  @override
  Future<String> readTextFile({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final bytes = await downloadFile(
      baseUrl: baseUrl,
      sid: sid,
      path: path,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );
    return utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Future<void> writeTextFile({
    required String baseUrl,
    required String sid,
    required String path,
    required String content,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final normalizedPath = _normalizeFolderPath(path);
    final slash = normalizedPath.lastIndexOf('/');
    final parentPath = slash <= 0 ? '/' : normalizedPath.substring(0, slash);
    final fileName = slash < 0 ? normalizedPath : normalizedPath.substring(slash + 1);

    await uploadFile(
      baseUrl: baseUrl,
      sid: sid,
      parentPath: parentPath,
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(content)),
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );
  }

  @override
  Future<Uint8List> downloadFile({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    DsmLogger.request(
      module: 'FileStation',
      action: 'download',
      method: 'GET',
      path: path,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.FileStation.Download',
        'method': 'download',
      },
    );

    final response = await client.get(
      '/webapi/entry.cgi',
      onReceiveProgress: onReceiveProgress,
      queryParameters: {
        'api': 'SYNO.FileStation.Download',
        'version': '2',
        'method': 'download',
        'mode': 'download',
        'path': jsonEncode([path]),
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader).copyWith(
        responseType: ResponseType.bytes,
      ),
    );

    final data = response.data;
    if (data is List<int>) {
      DsmLogger.success(
        module: 'FileStation',
        action: 'download',
        path: path,
        extra: {
          'bytes': data.length,
        },
      );
      return Uint8List.fromList(data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to download file: $path',
      response: response,
    );
  }

  Options _buildOptions({
    String? synoToken,
    String? cookieHeader,
  }) {
    final headers = <String, dynamic>{};
    if (synoToken != null && synoToken.isNotEmpty) {
      headers['X-SYNO-TOKEN'] = synoToken;
    }
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }
    return Options(headers: headers);
  }

  String _normalizeFolderPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  String _extractError({
    required String action,
    required dynamic data,
  }) {
    return DsmLogger.buildFailureMessage(
      module: 'FileStation',
      action: action,
      response: data,
    );
  }

  @override
  Future<List<FileItemModel>> listFiles({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final folderPath = _normalizeFolderPath(path);
    final isRoot = folderPath == '/';
    final action = isRoot ? 'listShare' : 'list';
    final payload = isRoot
        ? <String, dynamic>{
            'api': 'SYNO.FileStation.List',
            'method': 'list_share',
            'version': '2',
            'filetype': jsonEncode('dir'),
            'sort_by': jsonEncode('name'),
            'check_dir': 'true',
            'additional': jsonEncode([
              'real_path',
              'owner',
              'time',
              'perm',
              'mount_point_type',
              'sync_share',
              'volume_status',
              'indexed',
              'hybrid_share',
              'worm_share',
              'tiering_xattr',
            ]),
            'enum_cluster': 'true',
            'node': jsonEncode('fm_root'),
          }
        : <String, dynamic>{
            'api': 'SYNO.FileStation.List',
            'method': 'list',
            'version': '2',
            'offset': '0',
            'limit': '1000',
            'sort_by': jsonEncode('name'),
            'sort_direction': jsonEncode('ASC'),
            'action': jsonEncode('list'),
            'check_dir': 'true',
            'additional': jsonEncode([
              'real_path',
              'size',
              'owner',
              'time',
              'perm',
              'type',
              'mount_point_type',
              'description',
              'indexed',
            ]),
            'filetype': jsonEncode('all'),
            'folder_path': jsonEncode(folderPath),
          };

    DsmLogger.request(
      module: 'FileStation',
      action: action,
      method: 'POST',
      path: folderPath,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': payload['api'],
        'method': payload['method'],
        'version': payload['version'],
      },
    );

    final response = await client.post(
      '/webapi/entry.cgi',
      data: payload,
      options: _buildOptions(
        synoToken: synoToken,
        cookieHeader: cookieHeader,
      ).copyWith(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      final items = isRoot ? ((data['shares'] as List?) ?? const []) : ((data['files'] as List?) ?? const []);
      DsmLogger.success(
        module: 'FileStation',
        action: action,
        path: folderPath,
        extra: {
          'count': items.length,
        },
      );
      return items.whereType<Map>().map((map) {
        final additional = map['additional'] as Map? ?? const {};
        return FileItemModel(
          name: (map['name'] ?? '').toString(),
          path: (map['path'] ?? additional['real_path'] ?? '').toString(),
          isDirectory: ((map['isdir'] ?? false) == true),
          size: (additional['size'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: action,
      path: folderPath,
      response: response.data,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: action, data: response.data),
      response: response,
    );
  }

  @override
  Future<void> createFolder({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String name,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    final normalizedParentPath = _normalizeFolderPath(parentPath);
    DsmLogger.request(
      module: 'FileStation',
      action: 'createFolder',
      method: 'GET',
      path: normalizedParentPath,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'name': name,
      },
    );

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.CreateFolder',
        'version': '2',
        'method': 'create',
        'folder_path': normalizedParentPath,
        'name': name,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    if (response.data is Map && response.data['success'] == true) {
      DsmLogger.success(
        module: 'FileStation',
        action: 'createFolder',
        path: normalizedParentPath,
        extra: {'name': name},
      );
      return;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'createFolder',
      path: normalizedParentPath,
      response: response.data,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {'name': name},
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'createFolder', data: response.data),
      response: response,
    );
  }

  @override
  Future<void> rename({
    required String baseUrl,
    required String sid,
    required String path,
    required String newName,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    DsmLogger.request(
      module: 'FileStation',
      action: 'rename',
      method: 'GET',
      path: path,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {'newName': newName},
    );

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Rename',
        'version': '2',
        'method': 'rename',
        'path': path,
        'name': newName,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    if (response.data is Map && response.data['success'] == true) {
      DsmLogger.success(
        module: 'FileStation',
        action: 'rename',
        path: path,
        extra: {'newName': newName},
      );
      return;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'rename',
      path: path,
      response: response.data,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {'newName': newName},
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'rename', data: response.data),
      response: response,
    );
  }

  @override
  Future<void> delete({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    DsmLogger.request(
      module: 'FileStation',
      action: 'delete',
      method: 'GET',
      path: path,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Delete',
        'version': '2',
        'method': 'delete',
        'path': path,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    if (response.data is Map && response.data['success'] == true) {
      DsmLogger.success(
        module: 'FileStation',
        action: 'delete',
        path: path,
      );
      return;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'delete',
      path: path,
      response: response.data,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'delete', data: response.data),
      response: response,
    );
  }

  @override
  Future<String> createShareLink({
    required String baseUrl,
    required String sid,
    required String path,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    DsmLogger.request(
      module: 'FileStation',
      action: 'createShareLink',
      method: 'GET',
      path: path,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Sharing',
        'version': '3',
        'method': 'create',
        'path': path,
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      DsmLogger.success(
        module: 'FileStation',
        action: 'createShareLink',
        path: path,
        response: {
          'url': data['links'] ?? data['url'],
        },
      );
      return data['links']?.toString() ?? data['url']?.toString() ?? '分享链接创建成功';
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'createShareLink',
      path: path,
      response: response.data,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'createShareLink', data: response.data),
      response: response,
    );
  }

  @override
  Future<void> uploadFile({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
    String? synoToken,
    String? cookieHeader,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final normalizedParentPath = _normalizeFolderPath(parentPath);
    DsmLogger.request(
      module: 'FileStation',
      action: 'uploadFile',
      method: 'POST',
      path: normalizedParentPath,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'fileName': fileName,
        'bytes': bytes.length,
      },
    );

    final formData = FormData.fromMap({
      'overwrite': 'false',
      'path': normalizedParentPath,
      'mtime': DateTime.now().millisecondsSinceEpoch.toString(),
      'size': bytes.length.toString(),
      'api': 'SYNO.FileStation.Upload',
      'version': '2',
      'method': 'upload',
      '_sid': sid,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await client.post(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Upload',
        'method': 'upload',
        'version': '2',
        if (synoToken != null && synoToken.isNotEmpty) 'SynoToken': synoToken,
      },
      data: formData,
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    dynamic payload = response.data;
    if (payload is String) {
      try {
        payload = jsonDecode(payload);
      } catch (_) {}
    }

    DsmLogger.success(
      module: 'FileStation',
      action: 'uploadFileRaw',
      path: normalizedParentPath,
      response: payload,
    );

    if (payload is Map && payload['success'] == true) {
      DsmLogger.success(
        module: 'FileStation',
        action: 'uploadFile',
        path: normalizedParentPath,
        extra: {
          'fileName': fileName,
          'bytes': bytes.length,
        },
        response: payload,
      );
      return;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'uploadFile',
      path: normalizedParentPath,
      response: payload,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'fileName': fileName,
        'bytes': bytes.length,
      },
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'uploadFile', data: payload),
      response: response,
    );
  }
}
