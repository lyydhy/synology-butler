enum TransferTaskType { upload, download }

enum TransferTaskStatus { queued, running, success, failed }

class TransferTask {
  final String id;
  final TransferTaskType type;
  final TransferTaskStatus status;
  final String title;
  final String sourcePath;
  final String targetPath;
  final double progress;
  final String? errorMessage;
  final DateTime createdAt;

  const TransferTask({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.sourcePath,
    required this.targetPath,
    required this.progress,
    required this.createdAt,
    this.errorMessage,
  });

  TransferTask copyWith({
    TransferTaskType? type,
    TransferTaskStatus? status,
    String? title,
    String? sourcePath,
    String? targetPath,
    double? progress,
    String? errorMessage,
  }) {
    return TransferTask(
      id: id,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
