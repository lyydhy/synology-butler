import 'dart:typed_data';

import '../entities/file_item.dart';

abstract class FileRepository {
  Future<List<FileItem>> listFiles({
    required String path,
  });

  Future<void> createFolder({
    required String parentPath,
    required String name,
  });

  Future<void> rename({
    required String path,
    required String newName,
  });

  Future<void> delete({
    required String path,
  });

  Future<String> createShareLink({
    required String path,
  });

  Future<void> uploadFile({
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  });

  Future<Uint8List> downloadFile({
    required String path,
    void Function(int received, int total)? onReceiveProgress,
  });

  Future<String> readTextFile({
    required String path,
  });

  Future<void> writeTextFile({
    required String path,
    required String content,
  });
}
