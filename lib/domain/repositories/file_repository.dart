import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../entities/file_item.dart';
import '../entities/share_link.dart';

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

  Future<ShareLinkResult> createShareLink({
    required String path,
    String? dateExpired,
    int expireTimes = 0,
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

  Future<void> downloadFileToPath({
    required String path,
    required String localPath,
    void Function(int received, int total)? onReceiveProgress,
    CancelToken? cancelToken,
    int resumeFromBytes = 0,
  });

  Future<String> readTextFile({
    required String path,
  });

  Future<void> writeTextFile({
    required String path,
    required String content,
  });
}
