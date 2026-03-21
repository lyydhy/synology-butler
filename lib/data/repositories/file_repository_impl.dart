import 'dart:typed_data';

import '../../core/utils/server_url_helper.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';
import '../../domain/repositories/file_repository.dart';
import '../api/file_station_api.dart';

class FileRepositoryImpl implements FileRepository {
  const FileRepositoryImpl(this._api);

  final FileStationApi _api;

  @override
  Future<List<FileItem>> listFiles({
    required NasServer server,
    required NasSession session,
    required String path,
  }) async {
    final items = await _api.listFiles(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      path: path,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );

    return items
        .map(
          (item) => FileItem(
            name: item.name,
            path: item.path,
            isDirectory: item.isDirectory,
            size: item.size,
          ),
        )
        .toList();
  }

  @override
  Future<void> createFolder({
    required NasServer server,
    required NasSession session,
    required String parentPath,
    required String name,
  }) {
    return _api.createFolder(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      parentPath: parentPath,
      name: name,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<void> rename({
    required NasServer server,
    required NasSession session,
    required String path,
    required String newName,
  }) {
    return _api.rename(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      path: path,
      newName: newName,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<void> delete({
    required NasServer server,
    required NasSession session,
    required String path,
  }) {
    return _api.delete(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      path: path,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<String> createShareLink({
    required NasServer server,
    required NasSession session,
    required String path,
  }) {
    return _api.createShareLink(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      path: path,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<void> uploadFile({
    required NasServer server,
    required NasSession session,
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _api.uploadFile(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      parentPath: parentPath,
      fileName: fileName,
      bytes: bytes,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }

  @override
  Future<Uint8List> downloadFile({
    required NasServer server,
    required NasSession session,
    required String path,
  }) {
    return _api.downloadFile(
      baseUrl: ServerUrlHelper.buildBaseUrl(server),
      sid: session.sid,
      path: path,
      synoToken: session.synoToken,
      cookieHeader: session.cookieHeader,
    );
  }
}
