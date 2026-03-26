import '../../../../domain/repositories/package_repository.dart';

/// 套件安装流程中的页面共享状态。
///
/// 列表页和详情页都需要感知当前安装进度，
/// 因此这里保留一个轻量状态对象，避免把状态拆散成多个字段。
class PackageInstallState {
  const PackageInstallState({
    this.installingId,
    this.statusText,
    this.pendingQueueImpact,
  });

  /// 当前正在安装或更新的套件 id。
  final String? installingId;

  /// 当前安装任务展示给用户的状态文案。
  final String? statusText;

  /// 安装前检查得到的队列影响信息。
  final PackageQueueCheckResult? pendingQueueImpact;

  /// 当前套件是否正在安装。
  bool isInstalling(String packageId) => installingId == packageId;

  PackageInstallState copyWith({
    String? installingId,
    bool clearInstallingId = false,
    String? statusText,
    bool clearStatusText = false,
    PackageQueueCheckResult? pendingQueueImpact,
    bool clearPendingQueueImpact = false,
  }) {
    return PackageInstallState(
      installingId: clearInstallingId ? null : (installingId ?? this.installingId),
      statusText: clearStatusText ? null : (statusText ?? this.statusText),
      pendingQueueImpact: clearPendingQueueImpact
          ? null
          : (pendingQueueImpact ?? this.pendingQueueImpact),
    );
  }
}
