import 'dart:typed_data';

import '../entities/file_item.dart';
import '../entities/nas_server.dart';
import '../entities/nas_session.dart';

abstract class FileRepository {
  Future<List<FileItem>> listFiles({
    required NasServer server,
    required NasSession session,
    required String path,
  });

  Future<void> createFolder({
    required NasServer server,
    required NasSession session,
    required String parentPath,
    required String name,
  });

  Future<void> rename({
    required NasServer server,
    required NasSession session,
    required String path,
    required String newName,
  });

  Future<void> delete({
    required NasServer server,
    required NasSession session,
    required String path,
  });

  Future<String> createShareLink({
    required NasServer server,
    required NasSession session,
    required String path,
  });

  Future<void> uploadFile({
    required NasServer server,
    required NasSession session,
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  });

  Future<Uint8List> downloadFile({
    required NasServer server,
    required NasSession session,
    required String path,
  });

  Future<String> readTextFile({
    required NasServer server,
    required NasSession session,
    required String path,
  });

  Future<void> writeTextFile({
    required NasServer server,
    required NasSession session,
    required String path,
    required String content,
  });
}
