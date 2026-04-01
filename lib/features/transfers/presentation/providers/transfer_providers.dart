import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/transfer_notification_service.dart';
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
  
  TransferNotificationService get _notificationService => _ref.read(transferNotificationServiceProvider);

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
      totalBytes: bytes.length,
      receivedBytes: 0,
      createdAt: DateTime.now(),
    );
    state = [task, ...state];
    await _persist();
    await _runUpload(task.id, parentPath: parentPath, fileName: fileName, bytes: bytes);
  }

  Future<void> enqueueDownload({
    required String remotePath,
    required String displayName,
    int? estimatedSize,
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
      totalBytes: estimatedSize ?? 0,
      receivedBytes: 0,
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
    // 先删除旧记录
    state = state.where((t) => t.id != task.id).toList();
    await _persist();

    // 如果是下载任务，删除本地临时文件
    if (task.type == TransferTaskType.download) {
      final file = File(task.targetPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    // 创建新任务
    final retryId = _id();
    final retryTask = TransferTask(
      id: retryId,
      type: task.type,
      status: TransferTaskStatus.queued,
      title: task.title,
      sourcePath: task.sourcePath,
      targetPath: task.targetPath,
      progress: 0,
      receivedBytes: 0,
      totalBytes: task.totalBytes,
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
    await _persist();
  }

  Future<void> removeTask(String id, {bool deleteFile = false}) async {
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));

    // 取消通知
    final transferType = task.type == TransferTaskType.download ? TransferType.download : TransferType.upload;
    await _notificationService.cancel(id, transferType);

    // 如果正在下载，标记为取消
    if (task.status == TransferTaskStatus.running || task.status == TransferTaskStatus.queued) {
      // 删除本地临时文件
      if (task.type == TransferTaskType.download) {
        final file = File(task.targetPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    } else if (deleteFile && task.type == TransferTaskType.download && task.status == TransferTaskStatus.success) {
      // 已完成的下载，如果指定删除文件
      final file = File(task.targetPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    state = state.where((t) => t.id != id).toList();
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
    // 注册活跃上传并显示通知
    _notificationService.registerActive(id, TransferType.upload);
    await _notificationService.showProgress(
      taskId: id,
      type: TransferType.upload,
      fileName: fileName,
      receivedBytes: 0,
      totalBytes: bytes.length,
      isRunning: true,
    );

    _update(id, status: TransferTaskStatus.running, progress: 0.1, receivedBytes: 0, totalBytes: bytes.length);

    var candidateName = fileName;
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        await _ref.read(fileUploadProvider)(parentPath, candidateName, bytes);
        _update(
          id,
          status: TransferTaskStatus.success,
          progress: 1,
          receivedBytes: bytes.length,
          errorMessage: '$parentPath/$candidateName',
        );
        // 显示上传完成通知
        await _notificationService.showCompleted(
          taskId: id,
          type: TransferType.upload,
          fileName: fileName,
        );
        return;
      } catch (e) {
        final text = e.toString().toLowerCase();
        final looksLikeExists = text.contains('407') || text.contains('exist') || text.contains('already');
        if (!looksLikeExists) {
          _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString());
          // 显示上传失败通知
          await _notificationService.showFailed(
            taskId: id,
            type: TransferType.upload,
            fileName: fileName,
            errorMessage: e.toString(),
          );
          return;
        }

        candidateName = _renameLikeFinder(fileName, attempt + 1);
        _update(id, progress: 0.2 + (attempt * 0.02));
      }
    }

    _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '上传重命名重试次数过多');
    // 显示上传失败通知
    await _notificationService.showFailed(
      taskId: id,
      type: TransferType.upload,
      fileName: fileName,
      errorMessage: '上传重命名重试次数过多',
    );
  }

  Future<void> _runDownload(
    String id, {
    required String remotePath,
    required File targetFile,
  }) async {
    // 获取任务信息用于通知
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    final fileName = task.title;
    
    // 注册活跃下载并显示通知
    _notificationService.registerActive(id, TransferType.download);
    await _notificationService.showProgress(
      taskId: id,
      type: TransferType.download,
      fileName: fileName,
      receivedBytes: 0,
      totalBytes: 0,
      isRunning: true,
    );
    
    _update(id, status: TransferTaskStatus.running, progress: 0.1);
    try {
      await _ref.read(fileRepositoryProvider).downloadFileToPath(
            path: remotePath,
            localPath: targetFile.path,
            onReceiveProgress: (received, total) {
              if (total <= 0) {
                _update(id, progress: 0.1, receivedBytes: received, totalBytes: 0);
                _notificationService.showProgress(
                  taskId: id,
                  type: TransferType.download,
                  fileName: fileName,
                  receivedBytes: received,
                  totalBytes: 0,
                  isRunning: true,
                );
              } else {
                final progress = received / total;
                _update(id, progress: progress.clamp(0.0, 0.98), receivedBytes: received, totalBytes: total);
                _notificationService.showProgress(
                  taskId: id,
                  type: TransferType.download,
                  fileName: fileName,
                  receivedBytes: received,
                  totalBytes: total,
                  isRunning: true,
                );
              }
            },
          );

      _update(id, progress: 0.99);
      _update(id, status: TransferTaskStatus.success, progress: 1, errorMessage: '已保存到 ${targetFile.path}');
      
      // 显示完成通知
      await _notificationService.showCompleted(
        taskId: id,
        type: TransferType.download,
        fileName: fileName,
        filePath: targetFile.path,
      );
    } catch (e) {
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString());
      
      // 显示失败通知
      await _notificationService.showFailed(
        taskId: id,
        type: TransferType.download,
        fileName: fileName,
        errorMessage: e.toString(),
      );
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
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
  }) async {
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(
            status: status,
            progress: progress,
            receivedBytes: receivedBytes,
            totalBytes: totalBytes,
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
