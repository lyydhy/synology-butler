import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../core/utils/dsm_logger.dart';
import '../models/dsm_user_model.dart';
import '../models/dsm_group_model.dart';

/// 用户与群组 API
class UserGroupApi {
  Dio get _dio => businessDio();

  /// 获取用户列表
  Future<List<DsmUserModel>> fetchUsers() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.User',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'additional': jsonEncode(['email', 'description', 'expired']),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载用户列表失败' : '加载用户列表失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final users = ((data['users'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => DsmUserModel(
            name: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            email: (item['email'] ?? '').toString(),
            status: (item['expired'] ?? 'normal').toString(),
            isExpired: item['expired'] != 'normal' && item['expired'] != null,
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();

    return users;
  }

  /// 获取群组列表
  Future<List<DsmGroupModel>> fetchGroups() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Group',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'name_only': 'false',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '加载群组列表失败' : '加载群组列表失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final groups = ((data['groups'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => DsmGroupModel(
            name: (item['name'] ?? '').toString(),
            description: (item['description'] ?? '').toString(),
            memberCount: (item['members'] as List?)?.length ?? 0,
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();

    return groups;
  }

  /// 更新用户信息
  Future<void> updateUser({
    required String name,
    String? description,
    String? email,
    String? password,
  }) async {
    final client = _dio;

    final data = <String, dynamic>{
      'api': 'SYNO.Core.User',
      'method': 'set',
      'version': 1,
      'name': name,
    };

    if (description != null) data['description'] = description;
    if (email != null) data['email'] = email;
    if (password != null && password.isNotEmpty) data['password'] = password;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] != true) {
        final error = response.data['error']?['message'] ?? '更新用户失败';
        throw Exception(error);
      }

      DsmLogger.success(
        module: 'User',
        action: 'updateUser',
        response: {'name': name},
      );
    } catch (e) {
      DsmLogger.failure(
        module: 'User',
        action: 'updateUser',
        reason: '更新用户异常：$e',
      );
      rethrow;
    }
  }

  /// 设置用户状态（启用/禁用）
  Future<void> setUserStatus({
    required String name,
    required bool disabled,
  }) async {
    final client = _dio;

    try {
      final response = await client.post(
        '/webapi/entry.cgi',
        data: {
          'api': 'SYNO.Core.User',
          'method': 'set',
          'version': 1,
          'name': name,
          'expired': disabled ? 1 : 0,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.data is Map && response.data['success'] != true) {
        final error = response.data['error']?['message'] ?? '设置用户状态失败';
        throw Exception(error);
      }

      DsmLogger.success(
        module: 'User',
        action: 'setUserStatus',
        response: {'name': name, 'disabled': disabled},
      );
    } catch (e) {
      DsmLogger.failure(
        module: 'User',
        action: 'setUserStatus',
        reason: '设置用户状态异常：$e',
      );
      rethrow;
    }
  }
}
