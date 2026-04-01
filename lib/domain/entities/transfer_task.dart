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
  final int receivedBytes;
  final int totalBytes;
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
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  factory TransferTask.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? '';
    final statusName = json['status']?.toString() ?? '';

    return TransferTask(
      id: json['id']?.toString() ?? '',
      type: TransferTaskType.values.firstWhere(
        (item) => item.name == typeName,
        orElse: () => TransferTaskType.download,
      ),
      status: TransferTaskStatus.values.firstWhere(
        (item) => item.name == statusName,
        orElse: () => TransferTaskStatus.failed,
      ),
      title: json['title']?.toString() ?? '',
      sourcePath: json['sourcePath']?.toString() ?? '',
      targetPath: json['targetPath']?.toString() ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'title': title,
      'sourcePath': sourcePath,
      'targetPath': targetPath,
      'progress': progress,
      'receivedBytes': receivedBytes,
      'totalBytes': totalBytes,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransferTask copyWith({
    TransferTaskType? type,
    TransferTaskStatus? status,
    String? title,
    String? sourcePath,
    String? targetPath,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
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
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
