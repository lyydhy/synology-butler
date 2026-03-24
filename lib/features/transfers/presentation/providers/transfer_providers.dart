import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/platform_downloads_directory.dart';
import '../../../../domain/entities/transfer_task.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../files/presentation/providers/file_providers.dart';
import '../../../preferences/providers/preferences_providers.dart';

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

  Future<void> retryTask(TransferTask task) async {
    final retryId = _id();
    final retryTask = TransferTask(
      id: retryId,
      type: task.type,
      status: TransferTaskStatus.queued,
      title: task.title,
      sourcePath: task.sourcePath,
      targetPath: task.targetPath,
      progress: 0,
      createdAt: DateTime.now(),
    );
    state = [retryTask, ...state];

    if (task.type == TransferTaskType.download) {
      final targetFile = File(task.targetPath);
      await _runDownload(retryId, remotePath: task.sourcePath, targetFile: targetFile);
      return;
    }

    state = state.map((item) {
      if (item.id != retryId) return item;
      return item.copyWith(
        status: TransferTaskStatus.failed,
        progress: 1,
        errorMessage: '上传任务暂不支持从传输页直接重试，请回到文件页重新选择上传',
      );
    }).toList();
  }

  void removeTask(String id) {
    state = state.where((task) => task.id != id).toList();
  }

  void clearCompleted() {
    state = state.where((task) => task.status != TransferTaskStatus.success).toList();
  }

  void clearFailed() {
    state = state.where((task) => task.status != TransferTaskStatus.failed).toList();
  }

  Future<void> _runUpload(
    String id, {
    required String parentPath,
    required String fileName,
    required Uint8List bytes,
  }) async {
    _update(id, status: TransferTaskStatus.running, progress: 0.1);

    var candidateName = fileName;
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        await _ref.read(fileUploadProvider)(parentPath, candidateName, bytes);
        _update(
          id,
          status: TransferTaskStatus.success,
          progress: 1,
          errorMessage: '$parentPath/$candidateName',
        );
        return;
      } catch (e) {
        final text = e.toString().toLowerCase();
        final looksLikeExists = text.contains('407') || text.contains('exist') || text.contains('already');
        if (!looksLikeExists) {
          _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString());
          return;
        }

        candidateName = _renameLikeFinder(fileName, attempt + 1);
        _update(id, progress: 0.2 + (attempt * 0.02));
      }
    }

    _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '上传重命名重试次数过多');
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
            onReceiveProgress: (received, total) {
              if (total <= 0) return;
              final progress = received / total;
              _update(id, progress: progress.clamp(0.0, 0.98));
            },
          );

      _update(id, progress: 0.99);
      await targetFile.writeAsBytes(bytes, flush: true);
      _update(id, status: TransferTaskStatus.success, progress: 1, errorMessage: '已保存到 ${targetFile.path}');
    } catch (e) {
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString());
    }
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final savedPath = _ref.read(downloadDirectoryProvider);
    if (savedPath != null && savedPath.isNotEmpty) {
      final dir = Directory(savedPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    return PlatformDownloadsDirectory.resolve();
  }

  Future<File> _resolveUniqueFile(Directory dir, String fileName) async {
    var candidate = File('${dir.path}/$fileName');
    var index = 1;
    while (await candidate.exists()) {
      candidate = File('${dir.path}/${_renameLikeFinder(fileName, index)}');
      index++;
    }
    return candidate;
  }

  String _renameLikeFinder(String fileName, int index) {
    final dotIndex = fileName.lastIndexOf('.');
    final hasExt = dotIndex > 0 && dotIndex < fileName.length - 1;
    final baseName = hasExt ? fileName.substring(0, dotIndex) : fileName;
    final ext = hasExt ? fileName.substring(dotIndex) : '';
    return '$baseName ($index)$ext';
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

final latestFinishedDownloadProvider = Provider<TransferTask?>((ref) {
  final tasks = ref.watch(transferControllerProvider);
  final downloads = tasks.where((t) => t.type == TransferTaskType.download && t.status == TransferTaskStatus.success).toList();
  if (downloads.isEmpty) return null;
  downloads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return downloads.first;
});
