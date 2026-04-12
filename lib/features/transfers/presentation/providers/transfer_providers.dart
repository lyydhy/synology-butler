import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
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

  /// 正在运行的下载任务对应的 CancelToken，用于暂停/取消
  final Map<String, CancelToken> _cancelTokens = {};

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

    final id = _id();
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    final task = TransferTask(
      id: id,
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
    await _runDownload(id, remotePath: remotePath, targetFile: targetFile);
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
    if (task.type == TransferTaskType.download) {
      _cancelTokens[retryId] = CancelToken();
    }
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
          forcePersist: true,
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
          _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString(), forcePersist: true);
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

    _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '上传重命名重试次数过多', forcePersist: true);
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
    int resumeFromBytes = 0,
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
      receivedBytes: resumeFromBytes,
      totalBytes: 0,
      isRunning: true,
    );

    _update(id, status: TransferTaskStatus.running, progress: resumeFromBytes > 0 ? 0.1 : 0.0, receivedBytes: resumeFromBytes);
    int actualWritten = resumeFromBytes;
    try {
      actualWritten = await _ref.read(fileRepositoryProvider).downloadFileToPath(
            path: remotePath,
            localPath: targetFile.path,
            resumeFromBytes: resumeFromBytes,
            onReceiveProgress: (received, total) {
              final totalReceived = resumeFromBytes + received;
              if (total <= 0) {
                _update(id, progress: 0.1, receivedBytes: totalReceived, totalBytes: 0);
                _notificationService.showProgress(
                  taskId: id,
                  type: TransferType.download,
                  fileName: fileName,
                  receivedBytes: totalReceived,
                  totalBytes: 0,
                  isRunning: true,
                );
              } else {
                final progress = received / total;
                _update(id, progress: progress.clamp(0.0, 0.98), receivedBytes: totalReceived, totalBytes: total);
                // 节流通知更新，避免通知栏频繁刷新导致 UI 卡顿
                final now = DateTime.now();
                if (now.difference(_lastProgressNotify).inMilliseconds >= _progressNotifyThrottleMs) {
                  _lastProgressNotify = now;
                  _notificationService.showProgress(
                    taskId: id,
                    type: TransferType.download,
                    fileName: fileName,
                    receivedBytes: totalReceived,
                    totalBytes: total,
                    isRunning: true,
                  );
                }
              }
            },
            cancelToken: _cancelTokens[id],
          );

      // 下载完成，清理 cancelToken
      _cancelTokens.remove(id);

      _update(id, progress: 0.99);
      _update(id, status: TransferTaskStatus.success, progress: 1, errorMessage: '已保存到 ${targetFile.path}', forcePersist: true);

      // 显示完成通知
      await _notificationService.showCompleted(
        taskId: id,
        type: TransferType.download,
        fileName: fileName,
        filePath: targetFile.path,
      );
    } catch (e) {
      // Dio 取消（暂停/取消）不标记为失败
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _cancelTokens.remove(id);
        // cancel() 后可能有少量数据残存在缓冲区写入文件，
        // 用 truncate 截断到实际写入量，保持文件完整性
        try {
          final result = await Process.run(
            'truncate',
            ['-s', actualWritten.toString(), targetFile.path],
          );
          if (result.exitCode != 0) {
            print('truncate failed: ${result.stderr}');
          }
        } catch (err) {
          print('truncate error: $err');
        }
        return;
      }
      _cancelTokens.remove(id);
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: e.toString(), forcePersist: true);

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

  /// 暂停下载（不删除部分文件，可继续）
  Future<void> pauseDownload(String id) async {
    final token = _cancelTokens[id];
    if (token == null) return;
    token.cancel('paused');
    // 读取磁盘上的实际文件大小作为断点，
    // 而不用流式回调里节流更新的 receivedBytes（可能滞后）
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    final file = File(task.targetPath);
    final actualSize = await file.exists() ? await file.length() : 0;
    _update(id, status: TransferTaskStatus.paused, downloadedBytes: actualSize, forcePersist: true);
  }

  /// 继续被暂停的下载
  Future<void> resumeDownload(String id) async {
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    if (task.status != TransferTaskStatus.paused) return;

    // 读取磁盘实际大小作为断点（不用 UI 状态里的节流值）
    final targetFile = File(task.targetPath);
    final actualSize = await targetFile.exists() ? await targetFile.length() : 0;
    // 如果实际文件大小明显超过记录的断点（超过 2MB），
    // 说明 server 不支持 Range，之前的 resume 已经把完整文件追加到 partial file 里了。
    // 此时删掉文件重新开始，否则会一直翻倍。
    if (actualSize > task.downloadedBytes + 1024 * 1024 * 2) {
      await targetFile.delete();
      _update(id, status: TransferTaskStatus.paused, downloadedBytes: 0, forcePersist: true);
      return;
    }

    final newToken = CancelToken();
    _cancelTokens[id] = newToken;
    _runDownload(id, remotePath: task.sourcePath, targetFile: targetFile, resumeFromBytes: actualSize);
  }

  /// 取消下载（删除部分文件）
  Future<void> cancelDownload(String id) async {
    final token = _cancelTokens[id];
    if (token != null) {
      token.cancel('cancelled');
    }
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    // 删除部分文件
    final file = File(task.targetPath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
    _cancelTokens.remove(id);
    state = state.where((t) => t.id != id).toList();
    await _persist();
  }

  /// 上次持久化的时间
  DateTime _lastPersist = DateTime.now();

  /// 上次 UI 状态更新的时间（用于节流）
  DateTime _lastUiUpdate = DateTime.now();

  /// 持久化节流间隔（毫秒）
  static const int _persistThrottleMs = 1000;

  /// UI 状态更新节流间隔（毫秒），避免频繁重建 UI
  static const int _uiUpdateThrottleMs = 500;

  /// 进度通知节流间隔（毫秒）
  static const int _progressNotifyThrottleMs = 1000;

  /// 上次进度通知的时间
  DateTime _lastProgressNotify = DateTime.now();

  Future<void> _update(
    String id, {
    TransferTaskStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    int? downloadedBytes,
    bool forcePersist = false,
  }) async {
    final now = DateTime.now();

    // 节流 UI 状态更新：仅在状态变化或超过间隔时触发 rebuild
    final shouldNotifyUi = forcePersist ||
        status != null ||
        now.difference(_lastUiUpdate).inMilliseconds >= _uiUpdateThrottleMs;

    if (shouldNotifyUi) {
      _lastUiUpdate = now;
      state = [
        for (final task in state)
          if (task.id == id)
            task.copyWith(
              status: status,
              progress: progress,
              receivedBytes: receivedBytes,
              totalBytes: totalBytes,
              errorMessage: errorMessage,
              downloadedBytes: downloadedBytes,
            )
          else
            task,
      ];
    }

    // 节流持久化：只在状态变化或超过间隔时持久化
    final shouldPersist = forcePersist ||
        status != null ||
        now.difference(_lastPersist).inMilliseconds >= _persistThrottleMs;

    if (shouldPersist) {
      _lastPersist = now;
      await _persist();
    }
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
