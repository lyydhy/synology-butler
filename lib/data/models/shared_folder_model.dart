import 'package:flutter/foundation.dart';

import '../../core/utils/global_error_handler.dart';
import '../../domain/entities/shared_folder.dart';

class SharedFolderModel {
  static List<SharedFolder> parseList(List<dynamic> data) {
    return tryCatchSync(
      () => data.map((item) => parseItem(item as Map<String, dynamic>)).toList(),
      'SharedFolderModel.parseList',
    ) ?? <SharedFolder>[];
  }

  static SharedFolder parseItem(Map<String, dynamic> data) {
    // size_used / size_total 在某些 DSM 版本可能是 double，需要安全转换
    final usedSize = _toIntSafe(data['size_used']);
    final totalSize = _toIntSafe(data['size_total']);

    String usageText = '';
    if (usedSize != null && totalSize != null && totalSize > 0) {
      final usedGB = usedSize / (1024 * 1024 * 1024);
      final totalGB = totalSize / (1024 * 1024 * 1024);
      usageText = '${usedGB.toStringAsFixed(1)} GB / ${totalGB.toStringAsFixed(1)} GB';
    }

    return SharedFolder(
      name: data['name'] as String? ?? '',
      description: data['desc'] as String? ?? '',
      volumePath: data['vol_path'] as String? ?? '',
      fileSystem: data['file_system'] as String? ?? '',
      isReadOnly: data['is_readonly'] == true || data['is_force_readonly'] == true,
      isHidden: data['hidden'] == true || data['hidden'] == 1 || data['is_hidden'] == true,
      recycleBinEnabled: data['enable_recycle_bin'] == true || data['enable_recycle_bin'] == 1 || data['recyclebin'] == true || data['recyclebin'] == 1,
      recycleBinAdminOnly: data['recycle_bin_admin_only'] == true || data['recycle_bin_admin_only'] == 1,
      hideUnreadable: data['hide_unreadable'] == true || data['hide_unreadable'] == 1,
      encrypted: data['encryption'] == true || data['encryption'] == 1 || data['is_encrypted'] == true || data['is_encrypted'] == 1,
      enableShareCow: data['enable_share_cow'] == true || data['enable_share_cow'] == 1,
      enableShareCompress: data['enable_share_compress'] == true || data['enable_share_compress'] == 1,
      shareQuota: _toIntSafe(data['share_quota']),
      usedSize: usedSize,
      totalSize: totalSize,
      usageText: usageText,
      // 新增字段
      volumeName: data['volume_name'] as String?,
      volumeDesc: data['volume_desc'] as String?,
      unitePermission: data['unite_permission'] == true || data['unite_permission'] == 1,
      supportSnapshot: data['support_snapshot'] == true || data['support_snapshot'] == 1,
      isShareMoving: data['is_share_moving'] == true || data['is_share_moving'] == 1,
      quotaValue: _toIntSafe(data['quota_value']),
      shareQuotaUsed: _toIntSafe(data['share_quota_used']),
    );
  }

  /// 安全将任意数值类型转为 int，兼容 double / num / int / String
  static int? _toIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    // 兜底：尝试直接 cast（可能触发 TypeError，被外层 catch）
    try {
      return value as int;
    } on TypeError {
      try {
        return (value as double).round();
      } catch (_) {
        return null;
      }
    }
  }
}
