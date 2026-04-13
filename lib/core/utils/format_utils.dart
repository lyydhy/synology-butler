library;

/// 通用格式化工具函数（不依赖 BuildContext，可在任意上下文中使用）

/// 字节数 -> 人类可读字符串，如 "2.5 GB"
String formatBytes(double bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes;
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
  return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
}

/// 下载/上传速度格式化，如 "↓2.5 MB/s" 或 "↓2.5 MB/s ↑300 KB/s"
String formatSpeed(double down, double up) {
  if (down > 0 && up > 0) {
    return '\u2193${formatBytes(down)}/s \u2191${formatBytes(up)}/s';
  }
  if (down > 0) return '\u2193${formatBytes(down)}/s';
  if (up > 0) return '\u2191${formatBytes(up)}/s';
  return '';
}
