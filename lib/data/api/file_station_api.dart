import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../models/file_item_model.dart';

abstract class FileStationApi {
  Future<List<FileItemModel>> listFiles({
    required String baseUrl,
    required String sid,
    required String path,
  });

  Future<void> createFolder({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String name,
  });

  Future<void> rename({
    required String baseUrl,
    required String sid,
    required String path,
    required String newName,
  });

  Future<void> delete({
    required String baseUrl,
    required String sid,
    required String path,
  });

  Future<String> createShareLink({
    required String baseUrl,
    required String sid,
    required String path,
  });

  Future<void> uploadFile({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  });
}

class DsmFileStationApi implements FileStationApi {
  @override
  Future<List<FileItemModel>> listFiles({
    required String baseUrl,
    required String sid,
    required String path,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.List',
        'version': '2',
        'method': 'list',
        'folder_path': path,
        'additional': '["size","time","perm","type"]',
        '_sid': sid,
      },
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      final files = (data['files'] as List?) ?? const [];
      return files.map((item) {
        final map = item as Map;
        return FileItemModel(
          name: (map['name'] ?? '').toString(),
          path: (map['path'] ?? '').toString(),
          isDirectory: ((map['isdir'] ?? false) == true),
          size: (map['additional']?['size'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to list files',
      response: response,
    );
  }

  @override
  Future<void> createFolder({
    required String baseUrl,
    required String sid,
    required String parentPath,
    required String name,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;

    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.CreateFolder',
        'version': '2',
        'method': 'create',
        'folder_path': parentPath,
        'name': name,
        '_sid': sid,
      },
    );

    if (response.data is Map && response.data['success'] == true) {
      return;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to create folder',
      response: response,
    );
  }

  @override
  Future<void> rename({
    required String baseUrl,
    required String sid,
    required String path,
    required String newName,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
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
    );

    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to rename file',
      response: response,
    );
  }

  @override
  Future<void> delete({
    required String baseUrl,
    required String sid,
    required String path,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Delete',
        'version': '2',
        'method': 'delete',
        'path': path,
        '_sid': sid,
      },
    );

    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to delete file',
      response: response,
    );
  }

  @override
  Future<String> createShareLink({
    required String baseUrl,
    required String sid,
    required String path,
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final response = await client.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Sharing',
        'version': '3',
        'method': 'create',
        'path': path,
        '_sid': sid,
      },
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      return data['links']?.toString() ?? data['url']?.toString() ?? '分享链接创建成功';
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to create share link',
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
  }) async {
    final client = DioClient(baseUrl: baseUrl).dio;
    final formData = FormData.fromMap({
      'api': 'SYNO.FileStation.Upload',
      'version': '2',
      'method': 'upload',
      'path': parentPath,
      'create_parents': 'true',
      'overwrite': 'true',
      '_sid': sid,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await client.post('/webapi/entry.cgi', data: formData);
    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to upload file',
      response: response,
    );
  }
}
