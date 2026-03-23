import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/file_station_api.dart';
import '../../../../data/repositories/file_repository_impl.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../domain/repositories/file_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final currentPathProvider = StateProvider<String>((ref) => '/');
final fileSortProvider = StateProvider<String>((ref) => 'name');

final fileStationApiProvider = Provider<FileStationApi>((ref) => DsmFileStationApi());

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(ref.read(fileStationApiProvider));
});

final fileListProvider = FutureProvider<List<FileItem>>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);
  final path = ref.watch(currentPathProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  final files = await ref.read(fileRepositoryProvider).listFiles(
        server: server,
        session: session,
        path: path,
      );

  final sort = ref.watch(fileSortProvider);
  final sorted = [...files];

  if (sort == 'size') {
    sorted.sort((a, b) => b.size.compareTo(a.size));
  } else {
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  return sorted;
});

final fileActionProvider = Provider<Future<void> Function(String, String)>((ref) {
  return (parentPath, name) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);

    if (server == null || session == null) {
      throw Exception('No active NAS session');
    }

    await ref.read(fileRepositoryProvider).createFolder(
          server: server,
          session: session,
          parentPath: parentPath,
          name: name,
        );

    ref.invalidate(fileListProvider);
  };
});

final fileRenameProvider = Provider<Future<void> Function(String, String)>((ref) {
  return (path, newName) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(fileRepositoryProvider).rename(
          server: server,
          session: session,
          path: path,
          newName: newName,
        );
    ref.invalidate(fileListProvider);
  };
});

final fileDeleteProvider = Provider<Future<void> Function(String)>((ref) {
  return (path) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(fileRepositoryProvider).delete(
          server: server,
          session: session,
          path: path,
        );
    ref.invalidate(fileListProvider);
  };
});

final fileBatchDeleteProvider = Provider<Future<void> Function(List<String>)>((ref) {
  return (paths) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    for (final path in paths) {
      await ref.read(fileRepositoryProvider).delete(
            server: server,
            session: session,
            path: path,
          );
    }

    ref.invalidate(fileListProvider);
  };
});

final fileShareProvider = Provider<Future<String> Function(String)>((ref) {
  return (path) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    return ref.read(fileRepositoryProvider).createShareLink(
          server: server,
          session: session,
          path: path,
        );
  };
});

final fileUploadProvider = Provider<Future<void> Function(String, String, Uint8List)>((ref) {
  return (parentPath, fileName, bytes) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(fileRepositoryProvider).uploadFile(
          server: server,
          session: session,
          parentPath: parentPath,
          fileName: fileName,
          bytes: bytes,
        );
    ref.invalidate(fileListProvider);
  };
});
