class DownloadTaskModel {
  final String id;
  final String title;
  final String status;
  final double progress;

  const DownloadTaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
  });
}
