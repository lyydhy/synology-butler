import '../../domain/entities/shared_folder.dart';

class SharedFolderModel {
  static List<SharedFolder> parseList(List<dynamic> data) {
    return data.map((item) => parseItem(item as Map<String, dynamic>)).toList();
  }

  static SharedFolder parseItem(Map<String, dynamic> data) {
    // 解析使用量
    final usedSize = data['size_used'] as int?;
    final totalSize = data['size_total'] as int?;

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
      isHidden: data['hidden'] == true || data['is_hidden'] == true,
      recycleBinEnabled: data['enable_recycle_bin'] == true || data['recyclebin'] == true,
      recycleBinAdminOnly: data['recycle_bin_admin_only'] == true,
      hideUnreadable: data['hide_unreadable'] == true,
      encrypted: data['encryption'] == true || data['is_encrypted'] == true,
      enableShareCow: data['enable_share_cow'] == true,
      enableShareCompress: data['enable_share_compress'] == true,
      shareQuota: data['share_quota'] as int?,
      usedSize: usedSize,
      totalSize: totalSize,
      usageText: usageText,
      // 新增字段
      volumeName: data['volume_name'] as String?,
      volumeDesc: data['volume_desc'] as String?,
      unitePermission: data['unite_permission'] as bool?,
      supportSnapshot: data['support_snapshot'] as bool?,
      isShareMoving: data['is_share_moving'] as bool?,
      quotaValue: data['quota_value'] as int?,
      shareQuotaUsed: data['share_quota_used'] as int?,
    );
  }
}
