import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../models/download_task_model.dart';

abstract class DownloadStationApi {
  /// 检查 Download Station 是否可用
  Future<bool> isAvailable();

  Future<List<DownloadTaskModel>> listTasks();

  Future<List<String>> createTask({
    required List<String> urls,
    String destination = 'Download',
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

  Future<String> getDefaultDestination();
}

class DsmDownloadStationApi implements DownloadStationApi {
  Dio get _dio => businessDio();

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await _dio.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.Package',
          'version': '2',
          'method': 'list',
          'additional': '["status_sketch"]',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['success'] == true) {
        final packages = (response.data['data'] as Map?)?['packages'] as List? ?? [];
        return packages.any((p) => (p as Map?)?['id'] == 'DownloadStation');
      }
      return false;
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
        final detail = additional['detail'] as Map? ?? const {};
        final transfer = additional['transfer'] as Map? ?? const {};
        final sizeDownloaded = (transfer['size_downloaded'] as num?)?.toDouble() ?? 0;
        final sizeTotal = (map['size'] as num?)?.toDouble() ?? 0;
        final progress = sizeTotal > 0 ? (sizeDownloaded / sizeTotal) : 0.0;

        final statusCode = (detail['status'] ?? map['status'] ?? 99).toString();

        // 时间戳转 DateTime（秒级）
        DateTime? parseTs(dynamic s) {
          if (s == null) return null;
          final ms = (s is int ? s : int.tryParse(s.toString()));
          if (ms == null || ms == 0) return null;
          return DateTime.fromMillisecondsSinceEpoch(ms * 1000);
        }

        return DownloadTaskModel(
          id: (map['id'] ?? '').toString(),
          title: (map['title'] ?? '').toString(),
          status: statusCode,
          progress: progress,
          sizeTotal: sizeTotal,
          sizeDownloaded: sizeDownloaded,
          sizeUploaded: (transfer['size_uploaded'] as num?)?.toDouble() ?? 0,
          speedDownload: (transfer['speed_download'] as num?)?.toDouble() ?? 0,
          speedUpload: (transfer['speed_upload'] as num?)?.toDouble() ?? 0,
          destination: (detail['destination'] as String?) ?? '',
          uri: (detail['uri'] as String?) ?? '',
          connectedPeers: (detail['connected_leechers'] as num?)?.toInt() ?? 0,
          connectedSeeders: (detail['connected_seeders'] as num?)?.toInt() ?? 0,
          totalPeers: (detail['total_peers'] as num?)?.toInt() ?? 0,
          totalPieces: (detail['total_pieces'] as num?)?.toInt() ?? 0,
          downloadedPieces: (transfer['downloaded_pieces'] as num?)?.toInt() ?? 0,
          createdTime: parseTs(detail['created_time'] ?? map['create_time']),
          startedTime: parseTs(detail['started_time']),
          completedTime: parseTs(detail['completed_time']),
          seedElapsed: (detail['seed_elapsed'] as num?)?.toInt() ?? 0,
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
  Future<List<String>> createTask({
    required List<String> urls,
    String destination = 'Download',
  }) async {
    final response = await _dio.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.DownloadStation2.Task',
        'version': '2',
        'method': 'create',
        'type': 'url',
        'destination': destination,
        'create_list': true,
        'url': jsonEncode(urls),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? {};
      final taskIds = (data['task_id'] as List?)?.cast<String>() ?? [];
      return taskIds;
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
        'api': 'SYNO.DownloadStation2.Task',
        'version': '2',
        'method': 'pause',
        'id': [id],
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
        'api': 'SYNO.DownloadStation2.Task',
        'version': '2',
        'method': 'resume',
        'id': [id],
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
        'api': 'SYNO.DownloadStation2.Task',
        'version': '2',
        'method': 'delete',
        'id': [id],
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

  @override
  Future<String> getDefaultDestination() async {
    final response = await _dio.get(
      '/webapi/entry.cgi',
      queryParameters: {
        'api': 'SYNO.DownloadStation2.Settings.Location',
        'method': 'get',
        'version': '1',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data is Map && response.data['success'] == true) {
      final data = response.data['data'] as Map? ?? const {};
      return (data['default_destination'] as String?) ?? 'Download';
    }
    return 'Download';
  }
}
