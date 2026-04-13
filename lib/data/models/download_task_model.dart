class DownloadTaskModel {
  final String id;
  final String title;
  final String status;
  final double progress;
  // size
  final double sizeTotal;
  final double sizeDownloaded;
  final double sizeUploaded;
  // speed
  final double speedDownload;
  final double speedUpload;
  // detail
  final String destination;
  final String uri;
  final int connectedPeers;
  final int connectedSeeders;
  final int totalPeers;
  final int totalPieces;
  final int downloadedPieces;
  final DateTime? createdTime;
  final DateTime? startedTime;
  final DateTime? completedTime;
  final int seedElapsed; // seconds

  const DownloadTaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    this.sizeTotal = 0,
    this.sizeDownloaded = 0,
    this.sizeUploaded = 0,
    this.speedDownload = 0,
    this.speedUpload = 0,
    this.destination = '',
    this.uri = '',
    this.connectedPeers = 0,
    this.connectedSeeders = 0,
    this.totalPeers = 0,
    this.totalPieces = 0,
    this.downloadedPieces = 0,
    this.createdTime,
    this.startedTime,
    this.completedTime,
    this.seedElapsed = 0,
  });
}
