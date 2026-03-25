import 'package:dio/dio.dart';

import '../models/download_task_model.dart';

abstract class DownloadStationApi {
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
  DsmDownloadStationApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<DownloadTaskModel>> listTasks() async {
    final response = await _dio.get(
      '/webapi/DownloadStation/task.cgi',
      queryParameters: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'list',
        'additional': 'detail,transfer',
      },
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      final tasks = (data['tasks'] as List?) ?? const [];
      return tasks.map((item) {
        final map = item as Map;
        final additional = map['additional'] as Map? ?? const {};
        final transfer = additional['transfer'] as Map? ?? const {};
        final sizeDownloaded = (transfer['size_downloaded'] as num?)?.toDouble() ?? 0;
        final sizeTotal = (transfer['size_total'] as num?)?.toDouble() ?? 0;
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
    final response = await _dio.get(
      '/webapi/DownloadStation/task.cgi',
      queryParameters: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'create',
        'uri': uri,
      },
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
    final response = await _dio.get(
      '/webapi/DownloadStation/task.cgi',
      queryParameters: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'pause',
        'id': id,
      },
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
    final response = await _dio.get(
      '/webapi/DownloadStation/task.cgi',
      queryParameters: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'resume',
        'id': id,
      },
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
    final response = await _dio.get(
      '/webapi/DownloadStation/task.cgi',
      queryParameters: {
        'api': 'SYNO.DownloadStation.Task',
        'version': '1',
        'method': 'delete',
        'id': id,
        'force_complete': false,
      },
    );

    if (response.data is Map && response.data['success'] == true) return;

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Failed to delete task',
      response: response,
    );
  }
}
