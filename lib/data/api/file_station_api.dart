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

    DsmLogger.request(
      module: 'FileStation',
      action: 'list',
      method: 'GET',
      path: folderPath,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
      extra: {
        'api': 'SYNO.FileStation.List',
        'version': '2',
      },
    );

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.List',
        'version': '2',
        'method': 'list',
        'folder_path': folderPath,
        'offset': '0',
        'limit': '1000',
        'sort_by': 'name',
        'sort_direction': 'asc',
        'additional': '["real_path","size","time","perm","type"]',
        '_sid': sid,
      },
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      final files = (data['files'] as List?) ?? const [];
      DsmLogger.success(
        module: 'FileStation',
        action: 'list',
        path: folderPath,
        extra: {
          'count': files.length,
        },
      );
      return files.whereType<Map>().map((map) {
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
      action: 'list',
      path: folderPath,
      response: response.data,
      sid: sid,
      synoToken: synoToken,
      cookieHeader: cookieHeader,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'list', data: response.data),
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
      'api': 'SYNO.FileStation.Upload',
      'version': '2',
      'method': 'upload',
      'path': normalizedParentPath,
      'create_parents': 'true',
      'overwrite': 'true',
      '_sid': sid,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await client.post(
      '/webapi/entry.cgi',
      data: formData,
      options: _buildOptions(synoToken: synoToken, cookieHeader: cookieHeader),
    );
    if (response.data is Map && response.data['success'] == true) {
      DsmLogger.success(
        module: 'FileStation',
        action: 'uploadFile',
        path: normalizedParentPath,
        extra: {
          'fileName': fileName,
          'bytes': bytes.length,
        },
      );
      return;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'uploadFile',
      path: normalizedParentPath,
      response: response.data,
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
      error: _extractError(action: 'uploadFile', data: response.data),
      response: response,
    );
  }
}
