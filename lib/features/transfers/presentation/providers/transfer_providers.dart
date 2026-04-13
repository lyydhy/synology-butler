import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/transfer_notification_service.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../core/storage/platform_downloads_directory.dart';
import '../../../../domain/entities/transfer_task.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../files/presentation/providers/file_providers.dart';
import '../../../preferences/providers/preferences_providers.dart';

class TransferController extends StateNotifier<List<TransferTask>> {
  TransferController(this._ref) : super(const []) {
    _init();
  }

  Future<void> _init() async {
    await _initBgrDownloader();
    await _restore();
  }

  final Ref _ref;

  TransferNotificationService get _notificationService => _ref.read(transferNotificationServiceProvider);

  /// 我们的任务ID → background_downloader DownloadTask 对象的映射
  final Map<String, DownloadTask> _bdTaskMap = {};

  /// background_downloader 状态更新订阅
  StreamSubscription<TaskUpdate>? _bdUpdatesSubscription;

  /// FileDownloader.start() 是否已完成
  bool _bdReady = false;

  /// 初始化 background_downloader：注册回调并启动
  Future<void> _initBgrDownloader() async {
    // 注册任务状态/进度回调
    FileDownloader().registerCallbacks(
      taskStatusCallback: (TaskStatusUpdate update) {
        _onBgrStatus(update);
      },
      taskProgressCallback: (TaskProgressUpdate update) {
        _onBgrProgress(update);
      },
    );

    // 监听所有任务状态变化
    _bdUpdatesSubscription = FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        _onBgrStatus(update);
      } else if (update is TaskProgressUpdate) {
        _onBgrProgress(update);
      }
    });

    // 启动 FileDownloader（关键！不调用则任务永远不开始）
    debugPrint('[Download] calling FileDownloader.start()...');
    await FileDownloader().start();
    _bdReady = true;
    debugPrint('[Download] FileDownloader.start() done');
  }

  /// background_downloader 任务状态回调
  Future<void> _onBgrStatus(TaskStatusUpdate update) async {
    final task = update.task;
    // 找到我们对应的任务 ID
    final ourId = _bdTaskMap.entries
        .where((e) => e.value.taskId == task.taskId)
        .map((e) => e.key)
        .firstOrNull;
    if (ourId == null) return;

    switch (update.status) {
      case TaskStatus.running:
        _update(ourId, status: TransferTaskStatus.running, forcePersist: true);
        break;
      case TaskStatus.complete:
        // 检查文件是否有效（存在且有内容）
        final task = state.firstWhere((t) => t.id == ourId, orElse: () => throw StateError('Task not found'));
        final file = File(task.targetPath);
        final exists = await file.exists();
        final length = exists ? await file.length() : 0;
        
        if (exists && length > 0) {
          _update(ourId, status: TransferTaskStatus.success, progress: 1, forcePersist: true);
        } else {
          // 文件不存在或为空，视为下载失败，可重试
          _update(ourId, status: TransferTaskStatus.failed, progress: 1, errorMessage: '下载失败（文件为空），请重试', forcePersist: true);
        }
        break;
      case TaskStatus.canceled:
        _update(ourId, status: TransferTaskStatus.failed, progress: 1, errorMessage: '下载已取消', forcePersist: true);
        break;
      case TaskStatus.paused:
        break;
      case TaskStatus.failed:
        _update(ourId, status: TransferTaskStatus.failed, progress: 1, errorMessage: '下载失败', forcePersist: true);
        break;
      default:
        break;
    }
  }

  /// background_downloader 任务进度回调
  void _onBgrProgress(TaskProgressUpdate update) {
    final task = update.task;
    final ourId = _bdTaskMap.entries
        .where((e) => e.value.taskId == task.taskId)
        .map((e) => e.key)
        .firstOrNull;
    if (ourId == null) return;

    final progress = update.progress.clamp(0.0, 0.98);
    final expectedSize = update.expectedFileSize;
    final received = (expectedSize * progress).round();
    _update(
      ourId,
      progress: progress,
      receivedBytes: expectedSize > 0 ? received : null,
      totalBytes: expectedSize > 0 ? expectedSize : null,
    );
  }

  @override
  void dispose() {
    _bdUpdatesSubscription?.cancel();
    super.dispose();
  }

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
    // 确保 FileDownloader 已完全启动
    if (!_bdReady) {
      debugPrint('[Download] waiting for FileDownloader.start()...');
      while (!_bdReady) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    final targetDir = await _resolveDownloadDirectory();
    final targetFile = await _resolveUniqueFile(targetDir, displayName);

    final id = _id();

    // 构建 DSM 下载 URL（与 Dio 保持一致：使用完整的 baseUrl，sid 作为 query param）
    final conn = _ref.read(currentConnectionStoreProvider);
    final server = conn.server;
    if (server == null) {
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '无可用服务器连接', forcePersist: true);
      return;
    }
    final session = conn.session;
    if (session == null) {
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '无可用会话', forcePersist: true);
      return;
    }
    final baseUrl = ServerUrlHelper.buildBaseUrl(server);
    final sid = session.sid;
    final synoToken = session.synoToken;
    final cookieHeader = session.cookieHeader;
    // 构建 URL（GET 方法，path 作为 query param，与 FileStation API 保持一致）
    final encodedPath = Uri.encodeComponent(jsonEncode([remotePath]));
    final downloadUrl = '$baseUrl/webapi/entry.cgi?api=SYNO.FileStation.Download&version=2&method=download&mode=download&path=$encodedPath&_sid=$sid';

    // 构建 headers（与 Dio SessionAttachInterceptor 保持一致）
    final headers = <String, String>{};
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }
    if (synoToken != null && synoToken.isNotEmpty) {
      headers['X-SYNO-TOKEN'] = synoToken;
    }

    // 创建 background_downloader 任务
    // 使用 baseDirectory 指定下载目录，由 bd 插件解析完整路径
    final bdTask = DownloadTask(
      taskId: id,
      url: downloadUrl,
      headers: headers,
      filename: displayName,
      directory: targetDir.path,  // 使用完整绝对路径
      baseDirectory: BaseDirectory.root,  // 配合绝对路径使用 root
      allowPause: true,
      updates: Updates.statusAndProgress,
      retries: 3,
    );

    // 配置 bd 插件通知（自动显示进度/完成/失败通知）
    FileDownloader().configureNotificationForTask(
      bdTask,
      running: const TaskNotification('正在下载: {displayName}', '{filename} - {progress}'),
      complete: const TaskNotification('下载完成: {displayName}', '{filename}'),
      error: const TaskNotification('下载失败: {displayName}', '{filename}'),
      paused: const TaskNotification('下载暂停: {displayName}', '{filename}'),
      canceled: const TaskNotification('下载取消: {displayName}', '{filename}'),
      progressBar: true,
      tapOpensFile: true,
    );

    debugPrint('[Download] bdTask taskId=${bdTask.taskId} taskType=${bdTask.taskType} url=${bdTask.url}');

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

    // enqueue 后 background_downloader 自动在后台下载，状态通过 stream 回调更新
    try {
      final enqueued = await FileDownloader().enqueue(bdTask);
      debugPrint('[Download] enqueue $id → $enqueued');
      if (!enqueued) {
        _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '任务入队失败', forcePersist: true);
        return;
      }
    } catch (e) {
      debugPrint('[Download] enqueue $id error: $e');
      _update(id, status: TransferTaskStatus.failed, progress: 1, errorMessage: '下载启动失败: $e', forcePersist: true);
      return;
    }
    // 映射：我们的ID → DownloadTask 对象（pause/resume 需要完整 task 对象）
    _bdTaskMap[id] = bdTask;
    _update(id, status: TransferTaskStatus.running, forcePersist: true);
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
      await enqueueDownload(
        remotePath: task.sourcePath,
        displayName: task.title,
        estimatedSize: task.totalBytes,
      );
      // 删除旧任务记录（enqueueDownload 已创建新的）
      state = state.where((t) => t.id != retryId).toList();
      await _persist();
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

    // 如果正在下载，需要取消后台任务（bd 插件会自动处理通知）
    if (task.status == TransferTaskStatus.running || task.status == TransferTaskStatus.queued) {
      if (task.type == TransferTaskType.download) {
        // 取消后台下载任务
        final bdTask = _bdTaskMap[id];
        if (bdTask != null) {
          try {
            await FileDownloader().cancel(bdTask);
          } catch (_) {}
          _bdTaskMap.remove(id);
        }
        // 删除本地临时文件
        final file = File(task.targetPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      } else {
        // 上传任务取消通知
        await _notificationService.cancel(id, TransferType.upload);
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
    final bdTask = _bdTaskMap[id];
    if (bdTask == null) return;
    try {
      await FileDownloader().pause(bdTask);
    } catch (_) {
      // server 不支持 pause，忽略
    }
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    final file = File(task.targetPath);
    final actualSize = await file.exists() ? await file.length() : 0;
    _update(id, status: TransferTaskStatus.paused, downloadedBytes: actualSize, forcePersist: true);
  }

  /// 继续被暂停的下载
  Future<void> resumeDownload(String id) async {
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    if (task.status != TransferTaskStatus.paused) return;

    final bdTask = _bdTaskMap[id];
    if (bdTask == null) return;

    try {
      await FileDownloader().resume(bdTask);
      _update(id, status: TransferTaskStatus.running, forcePersist: true);
    } catch (_) {
      // resume 失败，删档重来
      final file = File(task.targetPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      // 重新发起下载
      await enqueueDownload(
        remotePath: task.sourcePath,
        displayName: task.title,
        estimatedSize: task.totalBytes,
      );
      // 删除旧任务记录
      state = state.where((t) => t.id != id).toList();
      _bdTaskMap.remove(id);
      await _persist();
    }
  }

  /// 取消下载（删除部分文件）
  Future<void> cancelDownload(String id) async {
    final bdTask = _bdTaskMap[id];
    if (bdTask != null) {
      try {
        await FileDownloader().cancel(bdTask);
      } catch (_) {}
      _bdTaskMap.remove(id);
    }
    final task = state.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));
    // 删除部分文件
    final file = File(task.targetPath);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
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
