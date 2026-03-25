import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/file_station_api.dart';
import '../../../../data/repositories/file_repository_impl.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../domain/repositories/file_repository.dart';
import '../../../auth/presentation/providers/business_connection_providers.dart';
import '../widgets/file_type_helper.dart';

final currentPathProvider = StateProvider<String>((ref) => '/');
final fileSortProvider = StateProvider<String>((ref) => 'type');

final fileStationApiProvider = Provider<FileStationApi>((ref) {
  return DsmFileStationApi(dio: ref.watch(businessDioProvider));
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(
    ref.read(fileStationApiProvider),
  );
});

final fileListProvider = FutureProvider<List<FileItem>>((ref) async {
  final path = ref.watch(currentPathProvider);

  final files = await ref.read(fileRepositoryProvider).listFiles(
        path: path,
      );

  final sort = ref.watch(fileSortProvider);
  final sorted = [...files];

  if (sort == 'size') {
    sorted.sort((a, b) => b.size.compareTo(a.size));
  } else if (sort == 'name') {
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  } else {
    sorted.sort((a, b) {
      final typeCompare = FileTypeHelper.sortTypeOrder(a).compareTo(FileTypeHelper.sortTypeOrder(b));
      if (typeCompare != 0) return typeCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  return sorted;
});

final fileActionProvider = Provider<Future<void> Function(String, String)>((ref) {
  return (parentPath, name) async {
    await ref.read(fileRepositoryProvider).createFolder(
          parentPath: parentPath,
          name: name,
        );

    ref.invalidate(fileListProvider);
  };
});

final fileRenameProvider = Provider<Future<void> Function(String, String)>((ref) {
  return (path, newName) async {
    await ref.read(fileRepositoryProvider).rename(
          path: path,
          newName: newName,
        );
    ref.invalidate(fileListProvider);
  };
});

final fileDeleteProvider = Provider<Future<void> Function(String)>((ref) {
  return (path) async {
    await ref.read(fileRepositoryProvider).delete(
          path: path,
        );
    ref.invalidate(fileListProvider);
  };
});

final fileBatchDeleteProvider = Provider<Future<void> Function(List<String>)>((ref) {
  return (paths) async {
    for (final path in paths) {
      await ref.read(fileRepositoryProvider).delete(
            path: path,
          );
    }

    ref.invalidate(fileListProvider);
  };
});

final fileShareProvider = Provider<Future<String> Function(String)>((ref) {
  return (path) async {
    return ref.read(fileRepositoryProvider).createShareLink(
          path: path,
        );
  };
});

final fileUploadProvider = Provider<Future<void> Function(String, String, Uint8List)>((ref) {
  return (parentPath, fileName, bytes) async {
    await ref.read(fileRepositoryProvider).uploadFile(
          parentPath: parentPath,
          fileName: fileName,
          bytes: bytes,
        );
    ref.invalidate(fileListProvider);
  };
});
