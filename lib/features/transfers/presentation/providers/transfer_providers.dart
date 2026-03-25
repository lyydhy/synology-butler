import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/platform_downloads_directory.dart';
import '../../../../domain/entities/transfer_task.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../files/presentation/providers/file_providers.dart';
import '../../../preferences/providers/preferences_providers.dart';

class TransferController extends StateNotifier<List<TransferTask>> {
  TransferController(this._ref) : super(const []) {
    _restore();
  }

  final Ref _ref;

  String _id() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  Future<void> _restore() async {
    final storage = _ref.read(localStorageProvider);
    final raw = await storage.readStringList(AppConstants.transferHistoryKey);
    if (raw.isEmpty) {
      return;
    }

    final restored = <TransferTask>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is! Map) continue;
        final task = TransferTask.fromJson(decoded.cast<String, dynamic>());
        if (task.id.isEmpty) continue;
        restored.add(_normalizeRestoredTask(task));
      } catch (_) {}
    }

    if (restored.isEmpty) {
      await storage.remove(AppConstants.transferHistoryKey);
      return;
    }

    restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = restored.take(100).toList();
    await _persist();
  }

  TransferTask _normalizeRestoredTask(TransferTask task) {
    if (task.status == TransferTaskStatus.queued || task.status == TransferTaskStatus.running) {
      return task.copyWith(
        status: TransferTaskStatus.failed,
        progress: 1,
        errorMessage: '应用重启或任务中断，传输未完成',
      );
    }
    return task;
  }

  Future<void> _persist() async {
    final storage = _ref.read(localStorageProvider);
    final trimmed = state.take(100).toList();
    if (trimmed.length != state.length) {
      state = trimmed;
    }
    await storage.writeStringList(
      AppConstants.transferHistoryKey,
      trimmed.map((task) => jsonEncode(task.toJson())).toList(),
    );
  }

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
    await _persist();
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
    await _persist();
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
    await _persist();

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

  Future<void> removeTask(String id) async {
    state = state.where((task) => task.id != id).toList();
    await _persist();
  }

  Future<void> clearCompleted() async {
    state = state.where((task) => task.status != TransferTaskStatus.success).toList();
    await _persist();
  }

  Future<void> clearFailed() async {
    state = state.where((task) => task.status != TransferTaskStatus.failed).toList();
    await _persist();
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
      final bytes = await _ref.read(fileRepositoryProvider).downloadFile(
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

  Future<void> _update(
    String id, {
    TransferTaskStatus? status,
    double? progress,
    String? errorMessage,
  }) async {
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
    await _persist();
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
