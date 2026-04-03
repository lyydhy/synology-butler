import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../models/index_service_model.dart';

/// 索引服务 API
class IndexServiceApi {
  Dio get _dio => businessDio();

  /// 获取索引服务状态
  Future<IndexServiceModel> fetchIndexService() async {
    final client = _dio;

    Future<Map<String, dynamic>> postEntry(Map<String, dynamic> data) async {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (response.data is Map && response.data['success'] == true) {
        return (response.data['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      }
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载索引服务失败' : '加载索引服务失败');
    }

    final compound = await postEntry({
      'api': 'SYNO.Entry.Request',
      'method': 'request',
      'version': '1',
      'stop_when_error': 'false',
      'mode': 'sequential',
      'compound': jsonEncode([
        {
          'api': 'SYNO.Foto.Index',
          'method': 'get',
          'version': 1,
        },
        {
          'api': 'SYNO.Foto.Thumbnail',
          'method': 'get',
          'version': 1,
        },
        {
          'api': 'SYNO.Foto.Index.Task',
          'method': 'list',
          'version': 1,
        },
      ]),
    });

    final indexData = _extractCompoundApiData(compound, 'SYNO.Foto.Index');
    final thumbnailData = _extractCompoundApiData(compound, 'SYNO.Foto.Thumbnail');
    final taskData = _extractCompoundApiData(compound, 'SYNO.Foto.Index.Task');
    final tasks = ((taskData['tasks'] as List?)?.cast<Map>() ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => IndexServiceTaskModel(
            id: (item['id'] ?? '').toString(),
            type: (item['type'] ?? item['action'] ?? '').toString(),
            status: (item['status'] ?? '').toString(),
            detail: (item['detail'] ?? item['path'])?.toString(),
          ),
        )
        .toList();

    final indexing = indexData['running'] == true || indexData['indexing'] == true;
    final statusText = (indexData['status_text'] ?? indexData['status'] ?? (indexing ? '索引进行中' : '空闲')).toString();
    final thumbnailQuality = int.tryParse((thumbnailData['quality'] ?? thumbnailData['thumb_quality'] ?? 2).toString()) ?? 2;

    return IndexServiceModel(
      indexing: indexing,
      statusText: statusText,
      thumbnailQuality: thumbnailQuality,
      tasks: tasks,
    );
  }

  /// 设置缩略图质量
  Future<void> setThumbnailQuality({required int quality}) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Foto.Thumbnail',
        'method': 'set',
        'version': '1',
        'quality': quality.toString(),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '设置缩图质量失败' : '设置缩图质量失败');
    }
  }

  /// 重建索引
  Future<void> rebuildIndex() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Foto.Index',
        'method': 'reindex',
        'version': '1',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '重建索引失败' : '重建索引失败');
    }
  }

  Map<String, dynamic> _extractCompoundApiData(Map<String, dynamic> compound, String apiName) {
    final result = (compound['result'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final item in result) {
      if (item['api'] == apiName) {
        return (item['data'] as Map<String, dynamic>?) ?? const {};
      }
    }
    return const {};
  }
}
