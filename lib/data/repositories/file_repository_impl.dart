import 'dart:typed_data';

import '../../domain/entities/file_item.dart';
import '../../domain/entities/share_link.dart';
import '../../domain/repositories/file_repository.dart';
import '../api/file_station_api.dart';

class FileRepositoryImpl implements FileRepository {
  const FileRepositoryImpl(this._api);

  final FileStationApi _api;

  @override
  Future<List<FileItem>> listFiles({
    required String path,
  }) async {
    final items = await _api.listFiles(path: path);

    return items
        .map(
          (item) => FileItem(
            name: item.name,
            path: item.path,
            isDirectory: item.isDirectory,
            size: item.size,
            modifiedAt: item.modifiedAt
          ),
        )
        .toList();
  }

  @override
  Future<void> createFolder({
    required String parentPath,
    required String name,
  }) {
    return _api.createFolder(
      parentPath: parentPath,
      name: name,
    );
  }

  @override
  Future<void> rename({
    required String path,
    required String newName,
  }) {
    return _api.rename(
      path: path,
      newName: newName,
    );
  }

  @override
  Future<void> delete({
    required String path,
  }) {
    return _api.delete(path: path);
  }

  @override
  Future<ShareLinkResult> createShareLink({
    required String path,
    String? dateExpired,
    int expireTimes = 0,
  }) {
    return _api.createShareLink(
      path: path,
      dateExpired: dateExpired,
      expireTimes: expireTimes,
    );
  }

  @override
  Future<void> uploadFile({
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _api.uploadFile(
      parentPath: parentPath,
      fileName: fileName,
      bytes: bytes,
    );
  }

  @override
  Future<Uint8List> downloadFile({
    required String path,
    void Function(int received, int total)? onReceiveProgress,
  }) {
    return _api.downloadFile(
      path: path,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<void> downloadFileToPath({
    required String path,
    required String localPath,
    void Function(int received, int total)? onReceiveProgress,
  }) {
    return _api.downloadFileToPath(
      path: path,
      localPath: localPath,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<String> readTextFile({
    required String path,
  }) {
    return _api.readTextFile(path: path);
  }

  @override
  Future<void> writeTextFile({
    required String path,
    required String content,
  }) {
    return _api.writeTextFile(
      path: path,
      content: content,
    );
  }
}
