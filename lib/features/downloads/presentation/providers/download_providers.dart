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
    state = const AsyncValue.loading();
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

final downloadActionProvider = Provider<Future<void> Function(String)>((ref) {
  return (rawInput) async {
    final urls = rawInput
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (urls.isEmpty) return;
    await ref.read(downloadRepositoryProvider).createTask(
      urls: urls,
      destination: AppConstants.downloadDefaultDestination,
    );
    ref.read(downloadListProvider.notifier).refresh();
  };
});

final downloadPauseProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(downloadRepositoryProvider).pauseTask(id: id);
    ref.read(downloadListProvider.notifier).refresh();
  };
});

final downloadResumeProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(downloadRepositoryProvider).resumeTask(id: id);
    ref.read(downloadListProvider.notifier).refresh();
  };
});

final downloadDeleteProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(downloadRepositoryProvider).deleteTask(id: id);
    ref.read(downloadListProvider.notifier).refresh();
  };
});
