class IndexServiceTaskModel {
  final String id;
  final String type;
  final String status;
  final String? detail;

  const IndexServiceTaskModel({
    required this.id,
    required this.type,
    required this.status,
    this.detail,
  });
}

class IndexServiceModel {
  final bool indexing;
  final String statusText;
  final int thumbnailQuality;
  final List<IndexServiceTaskModel> tasks;

  const IndexServiceModel({
    required this.indexing,
    required this.statusText,
    required this.thumbnailQuality,
    this.tasks = const [],
  });
}
