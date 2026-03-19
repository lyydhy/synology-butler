import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/download_station_api.dart';
import '../../../../data/repositories/download_repository_impl.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../../domain/repositories/download_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final downloadStationApiProvider = Provider<DownloadStationApi>((ref) => DsmDownloadStationApi());
final downloadFilterProvider = StateProvider<String>((ref) => 'all');

final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepositoryImpl(ref.read(downloadStationApiProvider));
});

final downloadListProvider = FutureProvider<List<DownloadTask>>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  final tasks = await ref.read(downloadRepositoryProvider).listTasks(
        server: server,
        session: session,
      );

  final filter = ref.watch(downloadFilterProvider);
  if (filter == 'all') return tasks;
  return tasks.where((task) => task.status == filter).toList();
});

final downloadActionProvider = Provider<Future<void> Function(String)>((ref) {
  return (uri) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);

    if (server == null || session == null) {
      throw Exception('No active NAS session');
    }

    await ref.read(downloadRepositoryProvider).createTask(
          server: server,
          session: session,
          uri: uri,
        );

    ref.invalidate(downloadListProvider);
  };
});

final downloadPauseProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');
    await ref.read(downloadRepositoryProvider).pauseTask(server: server, session: session, id: id);
    ref.invalidate(downloadListProvider);
  };
});

final downloadResumeProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');
    await ref.read(downloadRepositoryProvider).resumeTask(server: server, session: session, id: id);
    ref.invalidate(downloadListProvider);
  };
});

final downloadDeleteProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');
    await ref.read(downloadRepositoryProvider).deleteTask(server: server, session: session, id: id);
    ref.invalidate(downloadListProvider);
  };
});
