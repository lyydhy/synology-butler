import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../models/task_scheduler_model.dart';

/// 任务计划 API
class TaskSchedulerApi {
  Dio get _dio => businessDio();

  /// 获取任务计划列表
  Future<List<ScheduledTaskModel>> fetchScheduledTasks() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.TaskScheduler',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'sort_by': 'next_trigger_time',
        'sort_direction': 'DESC',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载任务计划失败' : '加载任务计划失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final tasks = ((data['tasks'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => ScheduledTaskModel(
            id: (item['id'] as num?)?.toInt() ?? 0,
            name: (item['name'] ?? '').toString(),
            owner: (item['owner'] ?? item['real_owner'] ?? '').toString(),
            type: (item['type'] ?? '').toString(),
            enabled: item['enable'] == true,
            running: item['running'] == true,
            nextTriggerTime: (item['next_trigger_time'] ?? '').toString(),
            records: const [],
          ),
        )
        .toList();

    return tasks;
  }

  /// 执行任务计划
  Future<void> runScheduledTask({required int id, required String type, required String name}) async {
    final client = _dio;
    final payload = type == 'event_script'
        ? {
            'api': 'SYNO.Core.EventScheduler',
            'method': 'run',
            'version': '1',
            'task_name': jsonEncode([name]),
          }
        : {
            'api': 'SYNO.Core.TaskScheduler',
            'method': 'run',
            'version': '1',
            'task': jsonEncode([id]),
          };
    final response = await client.post(
      '/webapi/entry.cgi',
      data: payload,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '执行任务计划失败' : '执行任务计划失败');
    }
  }

  /// 设置任务计划启用状态
  Future<void> setScheduledTaskEnabled({required int id, required bool enabled}) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.TaskScheduler',
        'method': 'set_enable',
        'version': '1',
        'status': jsonEncode([
          {
            'id': id,
            'enable': enabled,
          }
        ]),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '更新任务状态失败' : '更新任务状态失败');
    }
  }
}
