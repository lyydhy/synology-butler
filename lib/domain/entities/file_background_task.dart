class FileBackgroundTask {
  const FileBackgroundTask({
    required this.taskId,
    required this.type,
    required this.path,
    required this.finished,
    this.progress,
    this.raw = const {},
  });

  final String taskId;
  final String type;
  final String path;
  final bool finished;
  final double? progress;
  final Map<String, dynamic> raw;

  String get displayName {
    switch (type) {
      case 'copy':
        return '复制';
      case 'move':
        return '移动';
      case 'delete':
        return '删除';
      case 'compress':
        return '压缩';
      case 'extract':
        return '解压';
      default:
        return '后台任务';
    }
  }
}
