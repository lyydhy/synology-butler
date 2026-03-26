import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/file_station_api.dart';
import '../../../../data/repositories/file_repository_impl.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../domain/repositories/file_repository.dart';
import '../widgets/file_type_helper.dart';

final fileStationApiProvider = Provider<FileStationApi>((ref) {
  return DsmFileStationApi();
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(ref.read(fileStationApiProvider));
});

/// 文件列表查询参数。
///
/// 路径和排序都属于页面局部状态，因此由页面传入 provider family。
class FileListQuery {
  const FileListQuery({required this.path, required this.sort});

  final String path;
  final String sort;
}

/// 按路径和排序方式获取文件列表。
final fileListProvider = FutureProvider.family<List<FileItem>, FileListQuery>((ref, query) async {
  final files = await ref.read(fileRepositoryProvider).listFiles(path: query.path);
  final sorted = [...files];

  if (query.sort == 'size') {
    sorted.sort((a, b) => b.size.compareTo(a.size));
  } else if (query.sort == 'name') {
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
    await ref.read(fileRepositoryProvider).createFolder(parentPath: parentPath, name: name);
  };
});

final fileRenameProvider = Provider<Future<void> Function(String, String)>((ref) {
  return (path, newName) async {
    await ref.read(fileRepositoryProvider).rename(path: path, newName: newName);
  };
});

final fileDeleteProvider = Provider<Future<void> Function(String)>((ref) {
  return (path) async {
    await ref.read(fileRepositoryProvider).delete(path: path);
  };
});

final fileBatchDeleteProvider = Provider<Future<void> Function(List<String>)>((ref) {
  return (paths) async {
    for (final path in paths) {
      await ref.read(fileRepositoryProvider).delete(path: path);
    }
  };
});

final fileShareProvider = Provider<Future<String> Function(String)>((ref) {
  return (path) async {
    return ref.read(fileRepositoryProvider).createShareLink(path: path);
  };
});

final fileUploadProvider = Provider<Future<void> Function(String, String, Uint8List)>((ref) {
  return (parentPath, fileName, bytes) async {
    await ref.read(fileRepositoryProvider).uploadFile(
          parentPath: parentPath,
          fileName: fileName,
          bytes: bytes,
        );
  };
});
