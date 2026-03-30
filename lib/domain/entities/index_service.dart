class IndexServiceTask {
  final String id;
  final String type;
  final String status;
  final String? detail;

  const IndexServiceTask({
    required this.id,
    required this.type,
    required this.status,
    this.detail,
  });
}

class IndexServiceData {
  final bool indexing;
  final String statusText;
  final int thumbnailQuality;
  final List<IndexServiceTask> tasks;

  const IndexServiceData({
    required this.indexing,
    required this.statusText,
    required this.thumbnailQuality,
    this.tasks = const [],
  });
}
