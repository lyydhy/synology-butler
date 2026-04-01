import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/upgrade_status.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// 更新状态 Provider
final upgradeStatusProvider = FutureProvider<UpgradeStatus>((ref) async {
  return ref.read(systemRepositoryProvider).checkUpgrade();
});

/// 是否有可用更新
final hasUpdateProvider = Provider<bool>((ref) {
  final upgradeAsync = ref.watch(upgradeStatusProvider);
  return upgradeAsync.maybeWhen(
    data: (status) => status.hasUpdate,
    orElse: () => false,
  );
});
