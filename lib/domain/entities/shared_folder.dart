class SharedFolder {
  final String name;
  final String description;
  final String volumePath;
  final String fileSystem;
  final bool isReadOnly;
  final bool isHidden;
  final bool recycleBinEnabled;
  final bool recycleBinAdminOnly;
  final bool hideUnreadable;
  final bool encrypted;
  final bool enableShareCow;
  final bool enableShareCompress;
  final int? shareQuota;
  final int? usedSize;
  final int? totalSize;
  final String usageText;
  // 新增字段
  final String? volumeName;
  final String? volumeDesc;
  final bool? unitePermission;
  final bool? supportSnapshot;
  final bool? isShareMoving;
  final int? quotaValue;
  final int? shareQuotaUsed;

  const SharedFolder({
    required this.name,
    required this.description,
    required this.volumePath,
    required this.fileSystem,
    required this.isReadOnly,
    required this.isHidden,
    required this.recycleBinEnabled,
    this.recycleBinAdminOnly = false,
    this.hideUnreadable = false,
    required this.encrypted,
    this.enableShareCow = false,
    this.enableShareCompress = false,
    this.shareQuota,
    this.usedSize,
    this.totalSize,
    required this.usageText,
    this.volumeName,
    this.volumeDesc,
    this.unitePermission,
    this.supportSnapshot,
    this.isShareMoving,
    this.quotaValue,
    this.shareQuotaUsed,
  });

  /// 使用率百分比（0-100）
  double? get usagePercent {
    if (totalSize == null || totalSize == 0 || usedSize == null) return null;
    return (usedSize! / totalSize!) * 100;
  }

  /// 是否有配额限制
  bool get hasQuota => shareQuota != null && shareQuota! > 0;

  SharedFolder copyWith({
    String? name,
    String? description,
    String? volumePath,
    String? fileSystem,
    bool? isReadOnly,
    bool? isHidden,
    bool? recycleBinEnabled,
    bool? recycleBinAdminOnly,
    bool? hideUnreadable,
    bool? encrypted,
    bool? enableShareCow,
    bool? enableShareCompress,
    int? shareQuota,
    int? usedSize,
    int? totalSize,
    String? usageText,
    String? volumeName,
    String? volumeDesc,
    bool? unitePermission,
    bool? supportSnapshot,
    bool? isShareMoving,
    int? quotaValue,
    int? shareQuotaUsed,
  }) {
    return SharedFolder(
      name: name ?? this.name,
      description: description ?? this.description,
      volumePath: volumePath ?? this.volumePath,
      fileSystem: fileSystem ?? this.fileSystem,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isHidden: isHidden ?? this.isHidden,
      recycleBinEnabled: recycleBinEnabled ?? this.recycleBinEnabled,
      recycleBinAdminOnly: recycleBinAdminOnly ?? this.recycleBinAdminOnly,
      hideUnreadable: hideUnreadable ?? this.hideUnreadable,
      encrypted: encrypted ?? this.encrypted,
      enableShareCow: enableShareCow ?? this.enableShareCow,
      enableShareCompress: enableShareCompress ?? this.enableShareCompress,
      shareQuota: shareQuota ?? this.shareQuota,
      usedSize: usedSize ?? this.usedSize,
      totalSize: totalSize ?? this.totalSize,
      usageText: usageText ?? this.usageText,
      volumeName: volumeName ?? this.volumeName,
      volumeDesc: volumeDesc ?? this.volumeDesc,
      unitePermission: unitePermission ?? this.unitePermission,
      supportSnapshot: supportSnapshot ?? this.supportSnapshot,
      isShareMoving: isShareMoving ?? this.isShareMoving,
      quotaValue: quotaValue ?? this.quotaValue,
      shareQuotaUsed: shareQuotaUsed ?? this.shareQuotaUsed,
    );
  }
}

/// 创建/编辑共享文件夹的请求数据
class SharedFolderEditRequest {
  final String name;
  final String volumePath;
  final String description;
  final bool hidden;
  final bool enableRecycleBin;
  final bool recycleBinAdminOnly;
  final bool hideUnreadable;
  final bool encryption;
  final String? encryptionPassword;
  final bool enableShareCow;
  final bool enableShareCompress;
  final bool enableShareQuota;
  final int? shareQuotaMB;
  final String? oldName; // 编辑时传入原名称

  const SharedFolderEditRequest({
    required this.name,
    required this.volumePath,
    this.description = '',
    this.hidden = false,
    this.enableRecycleBin = false,
    this.recycleBinAdminOnly = false,
    this.hideUnreadable = false,
    this.encryption = false,
    this.encryptionPassword,
    this.enableShareCow = false,
    this.enableShareCompress = false,
    this.enableShareQuota = false,
    this.shareQuotaMB,
    this.oldName,
  });

  /// 是否为编辑模式
  bool get isEdit => oldName != null && oldName!.isNotEmpty;
}
