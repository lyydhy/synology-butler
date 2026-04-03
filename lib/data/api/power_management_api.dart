import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../../domain/entities/power_status.dart';
import '../../domain/entities/power_schedule_task.dart';

/// 电源管理 API
class PowerManagementApi {
  Dio get _dio => businessDio();

  /// 获取电源状态
  Future<PowerStatus> fetchPowerStatus() async {
    final client = _dio;

    final apis = [
      {'api': 'SYNO.Core.Hardware.ZRAM', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Hardware.PowerRecovery', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Hardware.BeepControl', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Hardware.FanSpeed', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Hardware.Led.Brightness', 'method': 'get', 'version': 1},
      {'api': 'SYNO.Core.Hardware.Hibernation', 'method': 'get', 'version': 1},
    ];

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'stop_when_error': false,
          'api': 'SYNO.Entry.Request',
          'method': 'request',
          'mode': '"sequential"',
          'compound': jsonEncode(apis),
          'version': 1,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        final result = response.data['data']?['result'] as List?;
        if (result != null) {
          return PowerStatus.fromApiResponse(result);
        }
      }

      DsmLogger.failure(
        module: 'Power',
        action: 'fetchPowerStatus',
        response: response.data,
        reason: '获取电源状态失败',
      );
      return const PowerStatus();
    } catch (e) {
      DsmLogger.failure(
        module: 'Power',
        action: 'fetchPowerStatus',
        reason: '获取电源状态异常：$e',
      );
      rethrow;
    }
  }

  /// 设置电源选项
  Future<void> setPowerSettings({
    int? ledBrightness,
    String? fanSpeedMode,
    bool? poweronBeep,
    bool? poweroffBeep,
  }) async {
    final client = _dio;
    final apis = <Map<String, dynamic>>[];

    if (ledBrightness != null) {
      apis.add({
        'api': 'SYNO.Core.Hardware.Led.Brightness',
        'method': 'set',
        'version': 1,
        'brightness': ledBrightness,
      });
    }

    if (fanSpeedMode != null) {
      apis.add({
        'api': 'SYNO.Core.Hardware.FanSpeed',
        'method': 'set',
        'version': 1,
        'fan_speed': fanSpeedMode,
      });
    }

    if (poweronBeep != null || poweroffBeep != null) {
      apis.add({
        'api': 'SYNO.Core.Hardware.BeepControl',
        'method': 'set',
        'version': 1,
        if (poweronBeep != null) 'poweron_beep': poweronBeep,
        if (poweroffBeep != null) 'poweroff_beep': poweroffBeep,
      });
    }

    if (apis.isEmpty) return;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'stop_when_error': false,
          'api': 'SYNO.Entry.Request',
          'method': 'request',
          'mode': '"sequential"',
          'compound': jsonEncode(apis),
          'version': 1,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] != true) {
        final error = response.data['error']?['message'] ?? '设置电源选项失败';
        throw Exception(error);
      }

      DsmLogger.success(
        module: 'Power',
        action: 'setPowerSettings',
        response: {'ledBrightness': ledBrightness, 'fanSpeedMode': fanSpeedMode},
      );
    } catch (e) {
      DsmLogger.failure(
        module: 'Power',
        action: 'setPowerSettings',
        reason: '设置电源选项异常：$e',
      );
      rethrow;
    }
  }

  /// 获取开关机计划
  Future<List<PowerScheduleTask>> fetchPowerSchedule() async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.Hardware.PowerSchedule',
          'method': 'load',
          'version': 1,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) return [];

        final tasks = <PowerScheduleTask>[];
        
        final powerOnTasks = data['poweron_tasks'] as List? ?? [];
        for (final task in powerOnTasks) {
          if (task is Map<String, dynamic>) {
            tasks.add(PowerScheduleTask.fromJson(task, PowerScheduleType.powerOn));
          }
        }

        final powerOffTasks = data['poweroff_tasks'] as List? ?? [];
        for (final task in powerOffTasks) {
          if (task is Map<String, dynamic>) {
            tasks.add(PowerScheduleTask.fromJson(task, PowerScheduleType.powerOff));
          }
        }

        // 按时间排序
        tasks.sort((a, b) {
          if (a.hour != b.hour) return a.hour.compareTo(b.hour);
          return a.minute.compareTo(b.minute);
        });

        return tasks;
      }

      DsmLogger.failure(
        module: 'Power',
        action: 'fetchPowerSchedule',
        response: response.data,
        reason: '获取开关机计划失败',
      );
      return [];
    } catch (e) {
      DsmLogger.failure(
        module: 'Power',
        action: 'fetchPowerSchedule',
        reason: '获取开关机计划异常：$e',
      );
      rethrow;
    }
  }

  /// 关机
  Future<void> shutdown({bool force = false}) async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.System',
          'version': 1,
          'method': 'shutdown',
          'force': force,
          'local': true,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] != true) {
        final error = response.data['error']?['message'] ?? '关机失败';
        throw Exception(error);
      }

      DsmLogger.success(
        module: 'System',
        action: 'shutdown',
        response: {'force': force},
      );
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'shutdown',
        reason: '关机异常：$e',
      );
      rethrow;
    }
  }

  /// 重启
  Future<void> reboot({bool force = false}) async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.System',
          'version': 1,
          'method': 'reboot',
          'force': force,
          'local': true,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] != true) {
        final error = response.data['error']?['message'] ?? '重启失败';
        throw Exception(error);
      }

      DsmLogger.success(
        module: 'System',
        action: 'reboot',
        response: {'force': force},
      );
    } catch (e) {
      DsmLogger.failure(
        module: 'System',
        action: 'reboot',
        reason: '重启异常：$e',
      );
      rethrow;
    }
  }
}
