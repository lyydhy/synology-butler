import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../models/download_task_model.dart';

abstract class DownloadStationApi {
  /// 检查 Download Station 是否可用
  Future<bool> isAvailable();

  Future<List<DownloadTaskModel>> listTasks();

  Future<void> createTask({
    required String uri,
  });

  Future<void> pauseTask({
    required String id,
  });

  Future<void> resumeTask({
    required String id,
  });

  Future<void> deleteTask({
    required String id,
  });
}

class DsmDownloadStationApi implements DownloadStationApi {
  Dio get _dio => businessDio();

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.DownloadStation2.Info',
          'version': '2',
          'method': 'getinfo',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return response.data is Map && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<DownloadTaskModel>> listTasks() async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.DownloadStation2.Task',
        'version': '2',
        'method': 'list',
        'sort_by': 'total_size',
        'order': 'ASC',
        'action': 'enum',
        'type_inverse': true,
        'limit': 25,
        'additional': 'detail,transfer',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      // SYNO.DownloadStation2.Task returns 'task' array, not 'tasks'
      final tasks = (data['task'] as List?) ?? const [];
      return tasks.map((item) {
        final map = item as Map;
        final additional = map['additional'] as Map? ?? const {};
        final transfer = additional['transfer'] as Map? ?? const {};
        final sizeDownloaded = (transfer['size_downloaded'] as num?)?.toDouble() ?? 0;
        final sizeTotal = (map['size'] as num?)?.toDouble() ?? 0;
        final progress = sizeTotal > 0 ? (sizeDownloaded / sizeTotal) : 0.0;

        return DownloadTaskModel(
          id: (map['id'] ?? '').toString(),
          title: (map['title'] ?? '').toString(),
          status: (map['status'] ?? 'unknown').toString(),
          progress: progress,
        );
      }).toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to list download tasks',
      response: response,
    );
  }

  @override
  Future<void> createTask({
    required String uri,
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'create',
        'uri': uri,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      return;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to create download task',
      response: response,
    );
  }

  @override
  Future<void> pauseTask({
    required String id,
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'pause',
        'id': id,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to pause task',
      response: response,
    );
  }

  @override
  Future<void> resumeTask({
    required String id,
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'resume',
        'id': id,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to resume task',
      response: response,
    );
  }

  @override
  Future<void> deleteTask({
    required String id,
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'delete',
        'id': id,
        'force_complete': false,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to delete task',
      response: response,
    );
  }
}
