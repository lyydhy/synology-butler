import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 下载完成事件
///
/// 只在下载真正从 running -> success 那一刻触发，
/// 不缓存、不补救、不持久化。
class DownloadCompletedEvent {
  final String taskId;
  final String fileName;
  final String filePath;
  final DateTime completedAt;

  const DownloadCompletedEvent({
    required this.taskId,
    required this.fileName,
    required this.filePath,
    required this.completedAt,
  });
}

/// 全局下载完成事件流
///
/// 使用方法：在 App 顶层使用 ref.listenManual 监听 transferControllerProvider，
/// 在回调中判断状态变化并发送事件。
/// 事件只消费一次，5s 后自动消失。
final downloadCompletedEventProvider = StateProvider<DownloadCompletedEvent?>((ref) => null);
