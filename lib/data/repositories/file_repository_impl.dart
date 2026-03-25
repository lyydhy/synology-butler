import 'dart:typed_data';

import '../../core/network/business_connection_context.dart';
import '../../core/utils/server_url_helper.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_repository.dart';
import '../api/file_station_api.dart';

class FileRepositoryImpl implements FileRepository {
  const FileRepositoryImpl(this._api, this._context);

  final FileStationApi _api;
  final BusinessConnectionContext _context;

  @override
  Future<List<FileItem>> listFiles({
    required String path,
  }) async {
    final items = await _api.listFiles(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
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
    required String parentPath,
    required String name,
  }) {
    return _api.createFolder(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      parentPath: parentPath,
      name: name,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<void> rename({
    required String path,
    required String newName,
  }) {
    return _api.rename(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
      newName: newName,
    );
  }

  @override
  Future<void> delete({
    required String path,
  }) {
    return _api.delete(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<String> createShareLink({
    required String path,
  }) {
    return _api.createShareLink(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<void> uploadFile({
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _api.uploadFile(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      parentPath: parentPath,
      fileName: fileName,
      bytes: bytes,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<Uint8List> downloadFile({
    required String path,
    void Function(int received, int total)? onReceiveProgress,
  }) {
    return _api.downloadFile(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<String> readTextFile({
    required String path,
  }) {
    return _api.readTextFile(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
    );
  }

  @override
  Future<void> writeTextFile({
    required String path,
    required String content,
  }) {
    return _api.writeTextFile(
      baseUrl: ServerUrlHelper.buildBaseUrl(_context.server),
      sid: _context.session.sid,
      path: path,
      synoToken: _context.session.synoToken,
      cookieHeader: _context.session.cookieHeader,
      content: content,
    );
  }
}
