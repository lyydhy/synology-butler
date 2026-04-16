import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dayfl/dayfl.dart';
import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_error_helper.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/file_background_task.dart';
import '../../domain/entities/share_link.dart';
import '../../domain/entities/file_item.dart';

abstract class FileStationApi {
  Future<List<FileItem>> listFiles({
    required String path,
  });

  Future<Uint8List> downloadFile({
    required String path,
    void Function(int received, int total)? onReceiveProgress,
  });

  /// 下载文件到本地路径，返回实际写入的总字节数（用于断点续传）
  Future<int> downloadFileToPath({
    required String path,
    required String localPath,
    void Function(int received, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    int resumeFromBytes = 0,
  });

  Future<String> readTextFile({
    required String path,
  });

  Future<void> writeTextFile({
    required String path,
    required String content,
  });

  /// 使用 SYNO.Core.File 保存文本文件（正确 API）
  Future<void> saveTextFile({
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

  Future<ShareLinkResult> createShareLink({
    required String path,
    String? dateExpired,
    int expireTimes = 0,
  });

  Future<void> editShareLink({
    required String shareId,
    required String url,
    required String path,
    String? dateAvailable,
    String? dateExpired,
    int expireTimes = 0,
  });

  /// 列出所有分享链接
  Future<List<ShareLinkResult>> listShareLinks({int offset = 0, int limit = 50});

  /// 清除无效分享链接
  Future<void> clearInvalidShareLinks();

  /// 删除分享链接
  Future<void> deleteShareLinks(List<String> ids);

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
    // 使用 SYNO.Core.File save API（正确方式）
    await saveTextFile(path: path, content: content);
  }

  @override
  Future<void> saveTextFile({
    required String path,
    required String content,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'saveTextFile',
      method: 'POST',
      path: path,
    );

    // base64 编码内容
    final encodedContent = base64Encode(utf8.encode(content));

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.File',
        'method': 'save',
        'version': 1,
        'file_path': '"$path"',
        'file_content': '"$encodedContent"',
        'codepage': '"GB18030"',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] != true) {
      DsmLogger.failure(
        module: 'FileStation',
        action: 'saveTextFile',
        path: path,
        response: response.data,
      );
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'saveTextFile failed: \${response.data}',
        response: response,
      );
    }

    DsmLogger.success(
      module: 'FileStation',
      action: 'saveTextFile',
      path: path,
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
  Future<int> downloadFileToPath({
    required String path,
    required String localPath,
    void Function(int received, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    /// 从指定字节数开始下载（用于断点续传）。
    /// 为 0 表示从头开始下载。
    int resumeFromBytes = 0,
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
        'resumeFrom': resumeFromBytes,
      },
    );

    final options = Options(responseType: ResponseType.stream);
    // 断点续传：发送 Range header
    if (resumeFromBytes > 0) {
      options.headers = {'Range': 'bytes=$resumeFromBytes-'};
    }

    final response = await _dio.get<ResponseBody>(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.FileStation.Download',
        'version': '2',
        'method': 'download',
        'mode': 'download',
        'path': jsonEncode([path]),
      },
      options: options,
      cancelToken: cancelToken,
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
    // 断点续传时追加写入，否则覆盖
    final sink = file.openWrite(mode: resumeFromBytes > 0 ? FileMode.append : FileMode.write);

    // 计算实际总大小（如果支持断点续传，Content-Range 会告诉我们总大小）
    int totalBytes = -1;
    if (resumeFromBytes > 0) {
      // 从响应头 Content-Range: bytes X-Y/TOTAL 中提取总大小
      final rangeHeader = body.headers['content-range']?.first;
      if (rangeHeader != null) {
        final slashIdx = rangeHeader.lastIndexOf('/');
        if (slashIdx >= 0) {
          totalBytes = int.tryParse(rangeHeader.substring(slashIdx + 1)) ?? -1;
        }
      }
    } else {
      // 从 0 开始：直接用 Content-Length
      final clHeader = body.headers[Headers.contentLengthHeader]?.first.trim();
      totalBytes = int.tryParse(clHeader ?? '') ?? -1;
    }

    var received = resumeFromBytes;

    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        onReceiveProgress?.call(received, totalBytes);
      }
      await sink.flush();
      await sink.close();
      DsmLogger.success(
        module: 'FileStation',
        action: 'downloadToPath',
        path: path,
        extra: {
          'bytes': received - resumeFromBytes,
          'totalBytes': totalBytes,
          'localPath': localPath,
        },
      );
      return received;
    } catch (error) {
      await sink.close();
      // 取消时不删除部分文件（保留以便续传）
      final isCancel = error is DioException && error.type == DioExceptionType.cancel;
      if (!isCancel && await file.exists()) {
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
  /// 创建分享链接
  /// [path] 文件或文件夹路径
  /// [dateExpired] 过期时间（ISO8601 格式，如 2025-12-31T23:59:59），null 表示不过期
  /// [expireTimes] 允许访问次数，0 表示无限制
  Future<ShareLinkResult> createShareLink({
    required String path,
    String? dateExpired,
    int expireTimes = 0,
  }) async {
    DsmLogger.request(
      module: 'FileStation',
      action: 'createShareLink',
      method: 'POST',
      path: path,
    );

    final data = <String, dynamic>{
      'api': 'SYNO.FileStation.Sharing',
      'version': '3',
      'method': 'create',
      'path': jsonEncode([path]),
    };
    if (dateExpired != null && dateExpired.isNotEmpty) {
      data['date_expired'] = dateExpired;
    }
    if (expireTimes > 0) {
      data['expire_times'] = expireTimes.toString();
    }

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      final resultData = response.data['data'] as Map? ?? const {};
      final links = resultData['links'] as List? ?? [];
      final linkMap = links.isNotEmpty ? (links.first as Map? ?? {}) : <String, dynamic>{};
      final shareResult = ShareLinkResult.fromMap(linkMap.cast<String, dynamic>());
      DsmLogger.success(
        module: 'FileStation',
        action: 'createShareLink',
        path: path,
        response: {'url': shareResult.url},
      );
      return shareResult;
    }

    DsmLogger.failure(
      module: 'FileStation',
      action: 'createShareLink',
      path: path,
      response: response.data,
    );

    final errorCode = DsmErrorHelper.extractErrorCode(response.data);
    throw DioException(
      requestOptions: response.requestOptions,
      error: DsmErrorHelper.mapErrorCode(errorCode) ?? '分享链接创建失败',
      response: response,
    );
  }

  /// 编辑分享链接（修改有效期等）
  @override
  Future<void> editShareLink({
    required String shareId,
    required String url,
    required String path,
    String? dateAvailable,
    String? dateExpired,
    int expireTimes = 0,
  }) async {
    final data = <String, dynamic>{
      'api': 'SYNO.FileStation.Sharing',
      'version': '3',
      'method': 'edit',
      'id': jsonEncode([shareId]),
      'url': jsonEncode([url]),
      'path': path,
    };
    if (dateAvailable != null && dateAvailable.isNotEmpty) {
      data['date_available'] = dateAvailable;
    }
    if (dateExpired != null && dateExpired.isNotEmpty) {
      data['date_expired'] = dateExpired;
    }
    if (expireTimes > 0) {
      data['expire_times'] = expireTimes.toString();
    }

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) return;

    final errorCode = DsmErrorHelper.extractErrorCode(response.data);
    throw DioException(
      requestOptions: response.requestOptions,
      error: DsmErrorHelper.mapErrorCode(errorCode) ?? '编辑分享链接失败',
      response: response,
    );
  }

  @override
  Future<List<ShareLinkResult>> listShareLinks({int offset = 0, int limit = 50}) async {
    final data = <String, dynamic>{
      'api': 'SYNO.FileStation.Sharing',
      'version': '3',
      'method': 'list',
      'offset': offset.toString(),
      'limit': limit.toString(),
      'filter_type': 'SYNO.SDS.App.FileStation3.Instance,SYNO.SDS.App.SharingUpload.Application',
    };

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      final resultData = response.data['data'] as Map? ?? {};
      final links = resultData['links'] as List? ?? [];
      return links
          .map((e) => ShareLinkResult.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
    }

    final errorCode = DsmErrorHelper.extractErrorCode(response.data);
    throw DioException(
      requestOptions: response.requestOptions,
      error: DsmErrorHelper.mapErrorCode(errorCode) ?? '获取分享链接列表失败',
      response: response,
    );
  }

  @override
  Future<void> clearInvalidShareLinks() async {
    final data = <String, dynamic>{
      'api': 'SYNO.FileStation.Sharing',
      'version': '2',
      'method': 'clear_invalid',
    };

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) return;

    final errorCode = DsmErrorHelper.extractErrorCode(response.data);
    throw DioException(
      requestOptions: response.requestOptions,
      error: DsmErrorHelper.mapErrorCode(errorCode) ?? '清除无效链接失败',
      response: response,
    );
  }

  @override
  Future<void> deleteShareLinks(List<String> ids) async {
    final data = <String, dynamic>{
      'api': 'SYNO.FileStation.Sharing',
      'version': '3',
      'method': 'delete',
      'id': jsonEncode(ids),
    };

    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) return;

    final errorCode = DsmErrorHelper.extractErrorCode(response.data);
    throw DioException(
      requestOptions: response.requestOptions,
      error: DsmErrorHelper.mapErrorCode(errorCode) ?? '删除分享链接失败',
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
      'overwrite': 'true',
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
