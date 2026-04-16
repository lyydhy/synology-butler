import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/api/download_station_api.dart';
import '../../../../data/repositories/download_repository_impl.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../../domain/repositories/download_repository.dart';

final downloadStationApiProvider = Provider<DownloadStationApi>((ref) {
  return DsmDownloadStationApi();
});

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepositoryImpl(ref.read(downloadStationApiProvider));
});

/// Download Station 任务列表轮询 provider。
/// 每隔 [AppConstants.downloadTaskPollIntervalSeconds] 秒自动刷新。
class DownloadListNotifier extends AsyncNotifier<List<DownloadTask>> {
  Timer? _timer;

  @override
  Future<List<DownloadTask>> build() async {
    ref.onDispose(() => _timer?.cancel());

    // 首次立即加载
    final data = await ref.read(downloadRepositoryProvider).listTasks();

    // 启动轮询
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: AppConstants.downloadTaskPollIntervalSeconds),
      (_) => _refresh(),
    );

    return data;
  }

  Future<void> _refresh() async {
    if (state.isLoading) return;
    state = await AsyncValue.guard(() => ref.read(downloadRepositoryProvider).listTasks());
  }

  Future<void> refresh() => _refresh();
}

final downloadListProvider = AsyncNotifierProvider<DownloadListNotifier, List<DownloadTask>>(
  DownloadListNotifier.new,
);

/// Download Station 是否可用（已安装且服务正常）
final downloadStationAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(downloadStationApiProvider).isAvailable();
});

/// 统一下载操作类，替代 pause/resume/delete/add 四个 provider
class DownloadActions {
  final Ref _ref;

  DownloadActions(this._ref);

  DownloadRepository get _repo => _ref.read(downloadRepositoryProvider);

  Future<void> add(String rawInput) async {
    final urls = rawInput
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    await _repo.createTask(
      urls: urls,
      destination: AppConstants.downloadDefaultDestination,
    );
    _ref.read(downloadListProvider.notifier).refresh();
  }

  Future<void> pause(String id) async {
    await _repo.pauseTask(id: id);
    _ref.read(downloadListProvider.notifier).refresh();
  }

  Future<void> resume(String id) async {
    await _repo.resumeTask(id: id);
    _ref.read(downloadListProvider.notifier).refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteTask(id: id);
    _ref.read(downloadListProvider.notifier).refresh();
  }
}

final downloadActionsProvider = Provider<DownloadActions>((ref) {
  return DownloadActions(ref);
});
