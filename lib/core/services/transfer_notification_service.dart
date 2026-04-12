import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 传输类型
enum TransferType { download, upload }

/// 传输前台通知服务
///
/// 管理上传/下载任务的通知显示，确保 Android 后台任务不被系统暂停。
class TransferNotificationService {
  static final TransferNotificationService _instance = TransferNotificationService._internal();
  factory TransferNotificationService() => _instance;
  TransferNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  /// 通知 ID 基数
  static const int _downloadNotificationIdBase = 1000;
  static const int _uploadNotificationIdBase = 2000;
  
  /// 已初始化标记
  bool _initialized = false;

  /// 活跃任务 ID 集合
  final Set<String> _activeDownloads = {};
  final Set<String> _activeUploads = {};

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    
    await _notifications.initialize(settings);
    _initialized = true;
  }

  /// 请求通知权限（Android 13+）
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// 显示传输进度通知
  Future<void> showProgress({
    required String taskId,
    required TransferType type,
    required String fileName,
    required int receivedBytes,
    required int totalBytes,
    required bool isRunning,
  }) async {
    await initialize();
    
    final progress = totalBytes > 0 ? (receivedBytes / totalBytes * 100).round() : 0;
    final progressText = totalBytes > 0 
        ? '${_formatBytes(receivedBytes)} / ${_formatBytes(totalBytes)}'
        : _formatBytes(receivedBytes);
    
    final isDownload = type == TransferType.download;
    final channelId = isDownload ? 'download_channel' : 'upload_channel';
    final channelName = isDownload ? '下载任务' : '上传任务';
    final channelDesc = isDownload ? '显示文件下载进度' : '显示文件上传进度';
    final title = isDownload ? '正在下载' : '正在上传';
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: isRunning,
      onlyAlertOnce: true,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    
    final notificationId = _getNotificationId(taskId, type);
    
    await _notifications.show(
      notificationId,
      fileName,
      '$title: $progressText',
      details,
    );
  }

  /// 显示传输完成通知
  Future<void> showCompleted({
    required String taskId,
    required TransferType type,
    required String fileName,
    String? filePath,
  }) async {
    await initialize();
    
    if (type == TransferType.download) {
      _activeDownloads.remove(taskId);
    } else {
      _activeUploads.remove(taskId);
    }
    
    final isDownload = type == TransferType.download;
    final channelId = isDownload ? 'download_channel' : 'upload_channel';
    final channelName = isDownload ? '下载任务' : '上传任务';
    final channelDesc = isDownload ? '显示文件下载进度' : '显示文件上传进度';
    final title = isDownload ? '下载完成' : '上传完成';
    final body = isDownload && filePath != null 
        ? '$fileName 已保存' 
        : '$fileName 已完成';
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: false,
      ongoing: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    
    final notificationId = _getNotificationId(taskId, type);
    
    await _notifications.show(
      notificationId,
      title,
      body,
      details,
    );
  }

  /// 显示传输失败通知
  Future<void> showFailed({
    required String taskId,
    required TransferType type,
    required String fileName,
    required String errorMessage,
  }) async {
    await initialize();
    
    if (type == TransferType.download) {
      _activeDownloads.remove(taskId);
    } else {
      _activeUploads.remove(taskId);
    }
    
    final isDownload = type == TransferType.download;
    final channelId = isDownload ? 'download_channel' : 'upload_channel';
    final channelName = isDownload ? '下载任务' : '上传任务';
    final channelDesc = isDownload ? '显示文件下载进度' : '显示文件上传进度';
    final title = isDownload ? '下载失败' : '上传失败';
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showProgress: false,
      ongoing: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    
    final notificationId = _getNotificationId(taskId, type);
    
    await _notifications.show(
      notificationId,
      title,
      '$fileName: $errorMessage',
      details,
    );
  }

  /// 取消通知
  Future<void> cancel(String taskId, TransferType type) async {
    if (type == TransferType.download) {
      _activeDownloads.remove(taskId);
    } else {
      _activeUploads.remove(taskId);
    }
    final notificationId = _getNotificationId(taskId, type);
    await _notifications.cancel(notificationId);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    _activeDownloads.clear();
    _activeUploads.clear();
    await _notifications.cancelAll();
  }

  /// 注册活跃任务
  void registerActive(String taskId, TransferType type) {
    if (type == TransferType.download) {
      _activeDownloads.add(taskId);
    } else {
      _activeUploads.add(taskId);
    }
  }

  /// 检查是否有活跃任务
  bool get hasActiveTransfers => _activeDownloads.isNotEmpty || _activeUploads.isNotEmpty;
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;
  bool get hasActiveUploads => _activeUploads.isNotEmpty;

  int _getNotificationId(String taskId, TransferType type) {
    final base = type == TransferType.download ? _downloadNotificationIdBase : _uploadNotificationIdBase;
    return base + (taskId.hashCode.abs() % 10000);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }
}

/// Provider
final transferNotificationServiceProvider = Provider<TransferNotificationService>((ref) {
  return TransferNotificationService();
});

/// 向后兼容的下载通知服务（委托给 TransferNotificationService）
class DownloadNotificationService {
  static final DownloadNotificationService _instance = DownloadNotificationService._internal();
  factory DownloadNotificationService() => _instance;
  DownloadNotificationService._internal();

  TransferNotificationService get _service => TransferNotificationService();

  Future<void> initialize() => _service.initialize();
  Future<bool> requestPermission() => _service.requestPermission();
  
  Future<void> showProgress({
    required String taskId,
    required String fileName,
    required int receivedBytes,
    required int totalBytes,
    required bool isRunning,
  }) => _service.showProgress(
    taskId: taskId,
    type: TransferType.download,
    fileName: fileName,
    receivedBytes: receivedBytes,
    totalBytes: totalBytes,
    isRunning: isRunning,
  );

  Future<void> showCompleted({
    required String taskId,
    required String fileName,
    required String filePath,
  }) => _service.showCompleted(
    taskId: taskId,
    type: TransferType.download,
    fileName: fileName,
    filePath: filePath,
  );

  Future<void> showFailed({
    required String taskId,
    required String fileName,
    required String errorMessage,
  }) => _service.showFailed(
    taskId: taskId,
    type: TransferType.download,
    fileName: fileName,
    errorMessage: errorMessage,
  );

  Future<void> cancel(String taskId) => _service.cancel(taskId, TransferType.download);
  Future<void> cancelAll() => _service.cancelAll();
  void registerActive(String taskId) => _service.registerActive(taskId, TransferType.download);
  bool get hasActiveDownloads => _service.hasActiveDownloads;
}

/// 向后兼容的 Provider
final downloadNotificationServiceProvider = Provider<DownloadNotificationService>((ref) {
  return DownloadNotificationService();
});
