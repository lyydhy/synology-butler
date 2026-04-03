/// 文件服务状态实体
class FileServiceStatus {
  const FileServiceStatus({
    required this.serviceName,
    required this.enabled,
    this.version,
    this.port,
    this.extraInfo = const {},
    this.transferLogEnabled = false,
  });

  /// 服务名称（SMB、NFS、FTP、AFP 等）
  final String serviceName;

  /// 是否启用
  final bool enabled;

  /// 协议版本（如 SMB1/SMB2/SMB3）
  final String? version;

  /// 端口号
  final int? port;

  /// 额外信息
  final Map<String, dynamic> extraInfo;

  /// 是否启用传输日志
  final bool transferLogEnabled;

  FileServiceStatus copyWith({
    String? serviceName,
    bool? enabled,
    String? version,
    int? port,
    Map<String, dynamic>? extraInfo,
    bool? transferLogEnabled,
  }) {
    return FileServiceStatus(
      serviceName: serviceName ?? this.serviceName,
      enabled: enabled ?? this.enabled,
      version: version ?? this.version,
      port: port ?? this.port,
      extraInfo: extraInfo ?? this.extraInfo,
      transferLogEnabled: transferLogEnabled ?? this.transferLogEnabled,
    );
  }
}

/// 所有文件服务的状态汇总
class FileServicesModel {
  const FileServicesModel({
    this.smb,
    this.nfs,
    this.ftp,
    this.afp,
    this.sftp,
  });

  final FileServiceStatus? smb;
  final FileServiceStatus? nfs;
  final FileServiceStatus? ftp;
  final FileServiceStatus? afp;
  final FileServiceStatus? sftp;

  List<FileServiceStatus> get allServices {
    return [smb, nfs, ftp, afp, sftp].whereType<FileServiceStatus>().toList();
  }

  int get enabledCount => allServices.where((s) => s.enabled).length;
}
