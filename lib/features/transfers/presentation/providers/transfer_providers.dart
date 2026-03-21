import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../domain/entities/transfer_task.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../files/presentation/providers/file_providers.dart';

class TransferController extends StateNotifier<List<TransferTask>> {
  TransferController(this._ref) : super(const []);

  final Ref _ref;

  String _id() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  Future<void> enqueueUpload({
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final task = TransferTask(
      id: _id(),
      type: TransferTaskType.upload,
      status: TransferTaskStatus.queued,
      title: fileName,
      sourcePath: fileName,
      targetPath: parentPath,
      progress: 0,
      createdAt: DateTime.now(),
    );
    state = [task, ...state];
    await _runUpload(task.id, parentPath: parentPath, fileName: fileName, bytes: bytes);
  }

  Future<void> enqueueDownload({
    required String remotePath,
    required String displayName,
  }) async {
    final targetDir = await _resolveDownloadDirectory();
    final targetFile = await _resolveUniqueFile(targetDir, displayName);

    final task = TransferTask(
      id: _id(),
      type: TransferTaskType.download,
      status: TransferTaskStatus.queued,
      title: displayName,
      sourcePath: remotePath,
      targetPath: targetFile.path,
      progress: 0,
      createdAt: DateTime.now(),
    );
    state = [task, ...state];
    await _runDownload(task.id, remotePath: remotePath, targetFile: targetFile);
  }

  Future<void> enqueueBatchDownload(List<(String remotePath, String displayName)> items) async {
    for (final item in items) {
      await enqueueDownload(remotePath: item.$1, displayName: item.$2);
    }
  }

  Future<void> _runUpload(
    String id, {
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _update(id, status: TransferTaskStatus.running, progress: 0.1);
    try {
      await _ref.read(fileUploadProvider)(parentPath, fileName, bytes);
      _update(id, status: TransferTaskStatus.success, progress: 1, errorMessage: null);
    } catch (e) {
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString());
    }
  }

  Future<void> _runDownload(
    String id, {
    required String remotePath,
    required File targetFile,
  }) async {
    _update(id, status: TransferTaskStatus.running, progress: 0.1);
    try {
      final server = _ref.read(currentServerProvider);
      final session = _ref.read(currentSessionProvider);
      if (server == null || session == null) {
        throw Exception('No active NAS session');
      }

      final bytes = await _ref.read(fileRepositoryProvider).downloadFile(
            server: server,
            session: session,
            path: remotePath,
          );

      _update(id, progress: 0.75);
      await targetFile.writeAsBytes(bytes, flush: true);
      _update(id, status: TransferTaskStatus.success, progress: 1, errorMessage: targetFile.path);
    } catch (e) {
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString());
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _resolveUniqueFile(Directory dir, String fileName) async {
    final dotIndex = fileName.lastIndexOf('.');
    final hasExt = dotIndex > 0 && dotIndex < fileName.length - 1;
    final baseName = hasExt ? fileName.substring(0, dotIndex) : fileName;
    final ext = hasExt ? fileName.substring(dotIndex) : '';

    var candidate = File('${dir.path}/$fileName');
    var index = 1;
    while (await candidate.exists()) {
      candidate = File('${dir.path}/${baseName} ($index)$ext');
      index++;
    }
    return candidate;
  }

  void _update(
    String id, {
    TransferTaskStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(
            status: status,
            progress: progress,
            errorMessage: errorMessage,
          )
        else
          task,
    ];
  }
}

final transferControllerProvider = StateNotifierProvider<TransferController, List<TransferTask>>((ref) {
  return TransferController(ref);
});

final activeTransferCountProvider = Provider<int>((ref) {
  return ref.watch(transferControllerProvider).where((t) => t.status == TransferTaskStatus.queued || t.status == TransferTaskStatus.running).length;
});
