import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/package_api.dart';
import '../../../../data/api/system_api.dart';
import '../../../../data/repositories/package_repository_impl.dart';
import '../../../../data/repositories/system_repository_impl.dart';
import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/system_status.dart';

/// 首页全局数据：存储概览 + 已安装套件列表
/// 登录后由 main_shell_page watch，统一请求后供首页各模块使用
class GlobalHomeData {
  final SystemStatus overview;
  final List<PackageItem> installedPackages;

  const GlobalHomeData({
    required this.overview,
    required this.installedPackages,
  });
}

class GlobalHomeNotifier extends AsyncNotifier<GlobalHomeData> {
  @override
  Future<GlobalHomeData> build() async {
    return await _fetch();
  }

  Future<GlobalHomeData> _fetch() async {
    final systemRepo = SystemRepositoryImpl(DsmSystemApi());
    final packageRepo = PackageRepositoryImpl(DsmPackageApi());

    final results = await Future.wait([
      systemRepo.fetchOverview(),
      packageRepo.fetchInstalledPackages(),
    ]);

    return GlobalHomeData(
      overview: results[0] as SystemStatus,
      installedPackages: results[1] as List<PackageItem>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}

final globalHomeProvider =
    AsyncNotifierProvider<GlobalHomeNotifier, GlobalHomeData>(
  GlobalHomeNotifier.new,
);
