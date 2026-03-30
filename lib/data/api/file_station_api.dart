import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dayfl/dayfl.dart';
import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/file_background_task.dart';
import '../../domain/entities/file_item.dart';

abstract class FileStationApi {
  Future<List<FileItem>> listFiles({
    required String path,
  });

  Future<Uint8List> downloadFile({
    required String path,
    void Function(int received, int total)? onReceiveProgress,
  });

  Future<void> downloadFileToPath({
    required String path,
    required String localPath,
    void Function(int received, int total)? onReceiveProgress,
  });

  Future<String> readTextFile({
    required String path,
  });

  Future<void> writeTextFile({
    required String path,
    required String content,
  });

  Future<void> createFolder({
    required String parentPath,
    required String name,
  });

  Future<void> rename({
    required String path,
    required String newName,
  });

  Future<void> delete({
    required String path,
  });

  Future<String> createShareLink({
    required String path,
  });

  Future<void> uploadFile({
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  });

  Future<List<FileBackgroundTask>> listBackgroundTasks();

  Future<FileBackgroundTask?> getBackgroundTaskStatus({
    required FileBackgroundTask task,
  });
}

class DsmFileStationApi implements FileStationApi {
  Dio get _dio => businessDio();

  @override
  Future<String> readTextFile({
    required String path,
  }) async {
    final bytes = await downloadFile(path: path);
    return utf8.decode(bytes, allowMalformed: true);
  }

  @override
  Future<void> writeTextFile({
    required String path,
    required String content,
  }) async {
    final normalizedPath = _normalizeFolderPath(path);
    final slash = normalizedPath.lastIndexOf('/');
    final parentPath = slash <= 0 ? '/' : normalizedPath.substring(0, slash);
    final fileName = slash < 0 ? normalizedPath : normalizedPath.substring(slash + 1);

    await uploadFile(
      parentPath: parentPath,
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }

  @override
  Future<Uint8List> downloadFile({
    required String path,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'download',
      method: 'GET',
      path: path,
      extra: {
        'api': 'SYNO.FileStation.Download',
        'method': 'download',
      },
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      onReceiveProgress: onReceiveProgress,
      queryParameters: {
        'api': 'SYNO.FileStation.Download',
        'version': '2',
        'method': 'download',
        'mode': 'download',
        'path': jsonEncode([path]),
      },
      options: Options(responseType: ResponseType.bytes),
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

  @override
  Future<void> downloadFileToPath({
    required String path,
    required String localPath,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'downloadToPath',
      method: 'GET',
      path: path,
      extra: {
        'api': 'SYNO.FileStation.Download',
        'method': 'download',
        'localPath': localPath,
      },
    );

    final response = await _dio.get<ResponseBody>(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Download',
        'version': '2',
        'method': 'download',
        'mode': 'download',
        'path': jsonEncode([path]),
      },
      options: Options(responseType: ResponseType.stream),
    );

    final body = response.data;
    if (body == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Failed to download file stream: $path',
        response: response,
      );
    }

    final file = File(localPath);
    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    final totalHeader = body.headers[Headers.contentLengthHeader]?.first.trim();
    final totalBytes = int.tryParse(totalHeader ?? '') ?? -1;
    var received = 0;

    try {
      await for (final chunk in body.stream) {
        received += chunk.length;
        sink.add(chunk);
        onReceiveProgress?.call(received, totalBytes);
      }
      await sink.flush();
      await sink.close();
      DsmLogger.success(
        module: 'FileStation',
        action: 'downloadToPath',
        path: path,
        extra: {
          'bytes': received,
          'localPath': localPath,
        },
      );
    } catch (error) {
      await sink.close();
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
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
  Future<List<FileItem>> listFiles({
    required String path,
  }) async {
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
      extra: {
        'api': payload['api'],
        'method': payload['method'],
        'version': payload['version'],
      },
    );

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: payload,
      options: Options(contentType: Headers.formUrlEncodedContentType),
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
        final time = additional['time'] as Map? ?? const {};
        final modifiedSeconds = (time['mtime'] as num?)?.toInt();
        return FileItem(
          name: (map['name'] ?? '').toString(),
          path: (map['path'] ?? additional['real_path'] ?? '').toString(),
          isDirectory: ((map['isdir'] ?? false) == true),
          size: (additional['size'] as num?)?.toInt() ?? 0,
          modifiedAt: Dayfl(modifiedSeconds).dateTime,
        );
      }).toList();
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: action,
      path: folderPath,
      response: response.data,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: action, data: response.data),
      response: response,
    );
  }

  @override
  Future<void> createFolder({
    required String parentPath,
    required String name,
  }) async {
    final normalizedParentPath = _normalizeFolderPath(parentPath);
    DsmLogger.request(
      module: 'FileStation',
      action: 'createFolder',
      method: 'GET',
      path: normalizedParentPath,
      extra: {
        'name': name,
      },
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.CreateFolder',
        'version': '2',
        'method': 'create',
        'folder_path': normalizedParentPath,
        'name': name,
      },
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
    required String path,
    required String newName,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'rename',
      method: 'GET',
      path: path,
      extra: {'newName': newName},
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Rename',
        'version': '2',
        'method': 'rename',
        'path': path,
        'name': newName,
      },
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
    required String path,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'delete',
      method: 'GET',
      path: path,
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Delete',
        'version': '2',
        'method': 'delete',
        'path': path,
      },
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
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'delete', data: response.data),
      response: response,
    );
  }

  @override
  Future<String> createShareLink({
    required String path,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'createShareLink',
      method: 'GET',
      path: path,
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Sharing',
        'version': '3',
        'method': 'create',
        'path': path,
      },
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
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'createShareLink', data: response.data),
      response: response,
    );
  }

  double? _readProgress(Map<String, dynamic> data) {
    final candidates = [
      data['progress'],
      data['processed'],
      data['percent'],
    ];

    for (final candidate in candidates) {
      if (candidate is num) {
        final value = candidate.toDouble();
        if (value <= 1) return (value * 100).clamp(0, 100);
        return value.clamp(0, 100);
      }
      final parsed = double.tryParse(candidate?.toString() ?? '');
      if (parsed != null) {
        if (parsed <= 1) return (parsed * 100).clamp(0, 100);
        return parsed.clamp(0, 100);
      }
    }
    return null;
  }

  FileBackgroundTask _mergeTaskStatus({
    required FileBackgroundTask task,
    required Map<String, dynamic> data,
  }) {
    final finished = data['finished'] == true;
    final progress = _readProgress(data);
    final path = (data['path'] ?? task.path).toString();

    return FileBackgroundTask(
      taskId: task.taskId,
      type: task.type,
      path: path,
      finished: finished,
      progress: progress,
      raw: data,
    );
  }

  @override
  Future<List<FileBackgroundTask>> listBackgroundTasks() async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'backgroundTask',
      method: 'GET',
      path: '/',
      extra: const {
        'api': 'SYNO.FileStation.BackgroundTask',
        'method': 'list',
        'version': '3',
      },
    );

    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.BackgroundTask',
        'version': '3',
        'method': 'list',
      },
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      final tasks = (data['tasks'] as List?) ?? const [];
      final result = tasks.whereType<Map>().map((task) {
        final api = (task['api'] ?? '').toString();
        final params = task['params'] as Map? ?? const {};
        final taskId = (task['taskid'] ?? '').toString();
        final type = switch (api) {
          'SYNO.FileStation.CopyMove' => (params['remove_src'] == true) ? 'move' : 'copy',
          'SYNO.FileStation.Delete' => 'delete',
          'SYNO.FileStation.Compress' => 'compress',
          'SYNO.FileStation.Extract' => 'extract',
          _ => '',
        };
        final pathValue = (params['path'] ?? params['dest_folder_path'] ?? '').toString();

        return FileBackgroundTask(
          taskId: taskId,
          type: type,
          path: pathValue,
          finished: false,
          raw: Map<String, dynamic>.from(task),
        );
      }).where((task) => task.taskId.isNotEmpty && task.type.isNotEmpty).toList();

      DsmLogger.success(
        module: 'FileStation',
        action: 'backgroundTask',
        path: '/',
        extra: {'count': result.length},
      );
      return result;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'backgroundTask',
      path: '/',
      response: response.data,
    );

    throw DioException(
      requestOptions: response.requestOptions,
      error: _extractError(action: 'backgroundTask', data: response.data),
      response: response,
    );
  }

  @override
  Future<FileBackgroundTask?> getBackgroundTaskStatus({
    required FileBackgroundTask task,
  }) async {
    final config = switch (task.type) {
      'copy' || 'move' => ('SYNO.FileStation.CopyMove', '3'),
      'delete' => ('SYNO.FileStation.Delete', '2'),
      'compress' => ('SYNO.FileStation.Compress', '2'),
      'extract' => ('SYNO.FileStation.Extract', '1'),
      _ => ('', ''),
    };

    if (config.$1.isEmpty) return task;

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'taskid': task.taskId,
        'api': config.$1,
        'method': 'status',
        'version': config.$2,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      return _mergeTaskStatus(task: task, data: Map<String, dynamic>.from(data));
    }

    return task;
  }

  @override
  Future<void> uploadFile({
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final normalizedParentPath = _normalizeFolderPath(parentPath);
    DsmLogger.request(
      module: 'FileStation',
      action: 'uploadFile',
      method: 'POST',
      path: normalizedParentPath,
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
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dio.post(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Upload',
        'method': 'upload',
        'version': '2',
      },
      data: formData,
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
