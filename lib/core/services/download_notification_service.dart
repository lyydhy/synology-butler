import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 下载前台通知服务
///
/// 管理下载任务的通知显示，确保 Android 后台下载不被系统暂停。
class DownloadNotificationService {
  static final DownloadNotificationService _instance = DownloadNotificationService._internal();
  factory DownloadNotificationService() => _instance;
  DownloadNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  /// 通知 ID 基数（下载任务通知从 1000 开始）
  static const int _notificationIdBase = 1000;
  
  /// 已初始化标记
  bool _initialized = false;

  /// 活跃的下载任务 ID 集合
  final Set<String> _activeDownloads = {};

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

  /// 显示下载进度通知
  Future<void> showProgress({
    required String taskId,
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
    
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      '下载任务',
      channelDescription: '显示文件下载进度',
      importance: Importance.low,
      priority: Priority.low,
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
    
    final notificationId = _getNotificationId(taskId);
    const title = '正在下载';
    
    await _notifications.show(
      notificationId,
      fileName,
      '$title: $progressText',
      details,
    );
  }

  /// 显示下载完成通知
  Future<void> showCompleted({
    required String taskId,
    required String fileName,
    required String filePath,
  }) async {
    await initialize();
    _activeDownloads.remove(taskId);
    
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      '下载任务',
      channelDescription: '显示文件下载进度',
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
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    
    final notificationId = _getNotificationId(taskId);
    
    await _notifications.show(
      notificationId,
      '下载完成',
      '$fileName 已保存',
      details,
    );
  }

  /// 显示下载失败通知
  Future<void> showFailed({
    required String taskId,
    required String fileName,
    required String errorMessage,
  }) async {
    await initialize();
    _activeDownloads.remove(taskId);
    
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      '下载任务',
      channelDescription: '显示文件下载进度',
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
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    
    final notificationId = _getNotificationId(taskId);
    
    await _notifications.show(
      notificationId,
      '下载失败',
      '$fileName: $errorMessage',
      details,
    );
  }

  /// 取消下载通知
  Future<void> cancel(String taskId) async {
    _activeDownloads.remove(taskId);
    final notificationId = _getNotificationId(taskId);
    await _notifications.cancel(notificationId);
  }

  /// 取消所有下载通知
  Future<void> cancelAll() async {
    _activeDownloads.clear();
    await _notifications.cancelAll();
  }

  /// 注册活跃下载任务
  void registerActive(String taskId) {
    _activeDownloads.add(taskId);
  }

  /// 检查是否有活跃下载
  bool get hasActiveDownloads => _activeDownloads.isNotEmpty;

  int _getNotificationId(String taskId) {
    // 使用 taskId 的 hashCode 确保通知 ID 稳定
    return _notificationIdBase + (taskId.hashCode.abs() % 10000);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }
}

/// Provider
final downloadNotificationServiceProvider = Provider<DownloadNotificationService>((ref) {
  return DownloadNotificationService();
});
