import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 下载任务原始列表。
///
/// 筛选状态属于页面局部状态，因此不再在 provider 内耦合过滤逻辑。
final downloadListProvider = FutureProvider<List<DownloadTask>>((ref) async {
  return ref.read(downloadRepositoryProvider).listTasks();
});

/// Download Station 是否可用（已安装且服务正常）
final downloadStationAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(downloadStationApiProvider).isAvailable();
});

final downloadActionProvider = Provider<Future<void> Function(String)>((ref) {
  return (uri) async {
    await ref.read(downloadRepositoryProvider).createTask(uri: uri);
    ref.invalidate(downloadListProvider);
  };
});

final downloadPauseProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(downloadRepositoryProvider).pauseTask(id: id);
    ref.invalidate(downloadListProvider);
  };
});

final downloadResumeProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(downloadRepositoryProvider).resumeTask(id: id);
    ref.invalidate(downloadListProvider);
  };
});

final downloadDeleteProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(downloadRepositoryProvider).deleteTask(id: id);
    ref.invalidate(downloadListProvider);
  };
});
