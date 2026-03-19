import '../../domain/entities/download_task.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/system_status.dart';

const mockSystemStatus = SystemStatus(
  serverName: '家里 NAS',
  dsmVersion: 'DSM 7.2',
  cpuUsage: 23.0,
  memoryUsage: 58.0,
  storageUsage: 71.0,
);

const mockFiles = [
  FileItem(name: 'photo', path: '/photo', isDirectory: true, size: 0),
  FileItem(name: 'video', path: '/video', isDirectory: true, size: 0),
  FileItem(name: 'movie.mkv', path: '/video/movie.mkv', isDirectory: false, size: 2147483648),
];

const mockDownloads = [
  DownloadTask(id: '1', title: 'Ubuntu ISO', status: 'downloading', progress: 0.64),
  DownloadTask(id: '2', title: 'Movie Pack', status: 'paused', progress: 0.31),
  DownloadTask(id: '3', title: 'Backup Archive', status: 'finished', progress: 1.0),
];
