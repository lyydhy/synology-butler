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

final downloadFilterProvider = StateProvider<String>((ref) => 'all');

final downloadListProvider = FutureProvider<List<DownloadTask>>((ref) async {
  final tasks = await ref.read(downloadRepositoryProvider).listTasks();

  final filter = ref.watch(downloadFilterProvider);
  if (filter == 'all') return tasks;
  return tasks.where((task) => task.status == filter).toList();
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
