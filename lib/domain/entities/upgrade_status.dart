/// DSM 更新状态
class UpgradeStatus {
  /// 是否有可用更新
  final bool hasUpdate;

  /// 可更新版本号（如 "7.2.2"）
  final String? availableVersion;

  /// 更新详细信息
  final UpgradeDetails? details;

  /// 当前检查时间
  final DateTime? checkedAt;

  const UpgradeStatus({
    required this.hasUpdate,
    this.availableVersion,
    this.details,
    this.checkedAt,
  });

  factory UpgradeStatus.fromApiResponse(Map<String, dynamic>? data) {
    if (data == null) {
      return const UpgradeStatus(hasUpdate: false);
    }

    final update = data['update'] as Map<String, dynamic>?;
    if (update == null) {
      return const UpgradeStatus(hasUpdate: false);
    }

    final available = update['available'] as bool? ?? false;
    final version = update['version']?.toString();
    final versionDetails = update['version_details'] as Map<String, dynamic>?;

    return UpgradeStatus(
      hasUpdate: available && version != null && version.isNotEmpty,
      availableVersion: version,
      details: versionDetails != null ? UpgradeDetails.fromJson(versionDetails) : null,
      checkedAt: DateTime.now(),
    );
  }

  /// 无更新状态
  static const noUpdate = UpgradeStatus(hasUpdate: false);

  /// 检查中状态
  static const checking = UpgradeStatus(hasUpdate: false);
}

/// 更新详细信息
class UpgradeDetails {
  final String? osName;
  final String? major;
  final String? minor;
  final String? micro;
  final String? nano;
  final String? buildNumber;
  final String? releaseNote;

  const UpgradeDetails({
    this.osName,
    this.major,
    this.minor,
    this.micro,
    this.nano,
    this.buildNumber,
    this.releaseNote,
  });

  factory UpgradeDetails.fromJson(Map<String, dynamic> json) {
    return UpgradeDetails(
      osName: json['os_name']?.toString(),
      major: json['major']?.toString(),
      minor: json['minor']?.toString(),
      micro: json['micro']?.toString(),
      nano: json['nano']?.toString(),
      buildNumber: json['buildnumber']?.toString(),
      releaseNote: json['release_note']?.toString(),
    );
  }

  /// 完整版本字符串
  String get fullVersion {
    final parts = <String>[];
    if (major != null && major!.isNotEmpty) parts.add(major!);
    if (minor != null && minor!.isNotEmpty) parts.add(minor!);
    if (micro != null && micro!.isNotEmpty) parts.add(micro!);
    if (nano != null && nano!.isNotEmpty) parts.add(nano!);
    return parts.isEmpty ? '' : parts.join('.');
  }

  /// 版本号 + build
  String get versionWithBuild {
    final version = fullVersion;
    if (version.isEmpty) return buildNumber ?? '';
    if (buildNumber == null || buildNumber!.isEmpty) return version;
    return '$version-$buildNumber';
  }
}
