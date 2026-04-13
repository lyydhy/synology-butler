// 通用格式化工具函数（不依赖 BuildContext，可在任意上下文中使用）

/// 字节数 -> 人类可读字符串，如 "2.5 GB"
String formatBytes(num? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
  return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
}

/// 下载/上传速度格式化，如 "↓2.5 MB/s" 或 "↓2.5 MB/s ↑300 KB/s"
String formatSpeed(num? down, num? up) {
  final d = down?.toDouble() ?? 0;
  final u = up?.toDouble() ?? 0;
  if (d > 0 && u > 0) {
    return '\u2193${formatBytes(d)}/s \u2191${formatBytes(u)}/s';
  }
  if (d > 0) return '\u2193${formatBytes(d)}/s';
  if (u > 0) return '\u2191${formatBytes(u)}/s';
  return '';
}
