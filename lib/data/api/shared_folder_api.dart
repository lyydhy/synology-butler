import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio.dart';
import '../../domain/entities/shared_folder.dart';
import '../models/shared_folder_model.dart';

/// 共享文件夹 API
class SharedFolderApi {
  Dio get _dio => businessDio();

  /// 获取共享文件夹列表
  Future<List<SharedFolder>> fetchSharedFolders() async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Share',
        'method': 'list',
        'version': '1',
        'offset': '0',
        'limit': '-1',
        'additional': jsonEncode([
          'size_used',
          'size_total',
          'quota',
          'recyclebin',
          'hidden',
          'encryption',
          'is_aclmode',
          'unite_permission',
          'is_support_acl',
          'is_sync_share',
          'is_readonly',
          'is_force_readonly',
          'force_readonly_reason',
          'hide_unreadable',
          'is_share_moving',
          'is_cluster_share',
          'is_exfat_share',
          'support_snapshot',
          'share_quota',
          'enable_share_compress',
          'enable_share_cow',
        ]),
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '获取共享文件夹列表失败' : '获取共享文件夹列表失败');
    }

    final data = response.data['data'] as Map? ?? const {};
    final shares = ((data['shares'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => SharedFolderModel.parseItem(item as Map<String, dynamic>))
        .toList();

    return shares;
  }

  /// 创建共享文件夹
  Future<void> createSharedFolder(SharedFolderEditRequest request) async {
    final client = _dio;
    final setData = <String, dynamic>{
      'api': 'SYNO.Core.Share',
      'method': 'create',
      'version': '1',
      'name': request.name,
      'desc': request.description,
      'vol_path': request.volumePath,
      'hidden': request.hidden ? 'true' : 'false',
      'enable_recycle_bin': request.enableRecycleBin ? 'true' : 'false',
      'recycle_bin_admin_only': request.recycleBinAdminOnly ? 'true' : 'false',
      'hide_unreadable': request.hideUnreadable ? 'true' : 'false',
    };

    final response = await client.post(
      '/webapi/entry.cgi',
      data: setData,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '创建共享文件夹失败' : '创建共享文件夹失败');
    }
  }

  /// 更新共享文件夹
  Future<void> updateSharedFolder(SharedFolderEditRequest request) async {
    final client = _dio;
    final setData = <String, dynamic>{
      'api': 'SYNO.Core.Share',
      'method': 'set',
      'version': '1',
      'name': request.oldName ?? request.name,
      'desc': request.description,
      'hidden': request.hidden ? 'true' : 'false',
      'enable_recycle_bin': request.enableRecycleBin ? 'true' : 'false',
      'recycle_bin_admin_only': request.recycleBinAdminOnly ? 'true' : 'false',
      'hide_unreadable': request.hideUnreadable ? 'true' : 'false',
    };

    final response = await client.post(
      '/webapi/entry.cgi',
      data: setData,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '更新共享文件夹失败' : '更新共享文件夹失败');
    }
  }

  /// 删除共享文件夹
  Future<void> deleteSharedFolder(String name) async {
    final client = _dio;
    final response = await client.post(
      '/webapi/entry.cgi',
      data: {
        'api': 'SYNO.Core.Share',
        'method': 'delete',
        'version': '1',
        'name': name,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (!(response.data is Map && response.data['success'] == true)) {
      throw Exception(response.data is Map ? response.data['error']?.toString() ?? '删除共享文件夹失败' : '删除共享文件夹失败');
    }
  }
}
