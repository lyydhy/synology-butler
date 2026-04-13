import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalAppLogFileSummary {
  const LocalAppLogFileSummary({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
}

class LocalAppLogStore {
  static final List<RegExp> _inlineValuePatterns = [
    RegExp(r'(password|passwd|pwd)\s*[:=]\s*([^\s,;]+)', caseSensitive: false),
    RegExp(r'(cookie|cookieheader|authorization|token|synotoken|sid)\s*[:=]\s*([^\s,;]+)', caseSensitive: false),
    RegExp(r'([?&](sid|synotoken|token|password|passwd))=([^&\s]+)', caseSensitive: false),
  ];

  static const _sensitiveLineKeys = [
    'password',
    'passwd',
    'pwd',
    'cookie',
    'cookieheader',
    'authorization',
    'token',
    'synotoken',
    'sid',
  ];

  static Future<Directory> resolveLogsDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${baseDir.path}/app_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    return logsDir;
  }

  static Future<List<LocalAppLogFileSummary>> listLogFiles() async {
    final logsDir = await resolveLogsDir();
    final entities = await logsDir.list().toList();
    final files = <LocalAppLogFileSummary>[];

    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.txt')) continue;
      final stat = await entity.stat();
      files.add(
        LocalAppLogFileSummary(
          name: entity.uri.pathSegments.isNotEmpty ? entity.uri.pathSegments.last : entity.path,
          path: entity.path,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }

    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  static Future<String> readLogFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return '';
    }
    final bytes = await file.readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // 遇到非法 UTF-8 字节时，用 replacementChar 替换
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static Future<String> readSanitizedLogFile(String path) async {
    final raw = await readLogFile(path);
    return sanitizeLogText(raw);
  }

  static String sanitizeLogText(String text) {
    if (text.isEmpty) return text;

    final lines = text.split('\n');
    final sanitized = lines.map(_sanitizeLine).join('\n');
    return sanitized;
  }

  static String _sanitizeLine(String line) {
    if (line.trim().isEmpty) return line;

    var sanitized = line;

    for (final pattern in _inlineValuePatterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        if (match.groupCount >= 4 && match.group(0)?.startsWith(RegExp(r'[_?&]')) != true) {
          final key = match.group(1) ?? 'secret';
          return '$key=[REDACTED]';
        }

        final full = match.group(0) ?? '';
        final key = match.group(1) ?? match.group(2) ?? 'secret';
        if (full.startsWith('?') || full.startsWith('&') || full.startsWith('_')) {
          final prefix = full.substring(0, 1);
          return '$prefix$key=[REDACTED]';
        }
        return '$key=[REDACTED]';
      });
    }

    final lowerLine = sanitized.toLowerCase().trimLeft();
    for (final key in _sensitiveLineKeys) {
      if (lowerLine.startsWith('- $key:') || lowerLine.startsWith('$key:')) {
        final colonIndex = sanitized.indexOf(':');
        if (colonIndex >= 0) {
          return '${sanitized.substring(0, colonIndex + 1)} [REDACTED]';
        }
      }
      if (lowerLine.startsWith('- $key=') || lowerLine.startsWith('$key=')) {
        final equalIndex = sanitized.indexOf('=');
        if (equalIndex >= 0) {
          return '${sanitized.substring(0, equalIndex + 1)} [REDACTED]';
        }
      }
    }

    return sanitized;
  }

  static Future<String> exportSanitizedLogFile(String sourcePath) async {
    final logsDir = await resolveLogsDir();
    final source = File(sourcePath);
    final name = source.uri.pathSegments.isNotEmpty ? source.uri.pathSegments.last : 'log.txt';
    final sanitizedName = name.replaceAll('.txt', '.sanitized.txt');
    final exportFile = File('${logsDir.path}/$sanitizedName');
    final content = await readSanitizedLogFile(sourcePath);
    await exportFile.writeAsString(content, flush: true);
    return exportFile.path;
  }

  static Future<String> exportSanitizedLogFileToDirectory({
    required String sourcePath,
    required String targetDirectory,
  }) async {
    final source = File(sourcePath);
    final name = source.uri.pathSegments.isNotEmpty ? source.uri.pathSegments.last : 'log.txt';
    final sanitizedName = name.replaceAll('.txt', '.sanitized.txt');
    final exportFile = File('$targetDirectory/$sanitizedName');
    final content = await readSanitizedLogFile(sourcePath);
    await exportFile.writeAsString(content, flush: true);
    return exportFile.path;
  }

  static Future<void> clearLogFile(String path) async {
    await deleteLogFile(path);
  }

  static Future<void> deleteLogFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    await file.delete();
  }

  static Future<void> clearAllLogs() async {
    final files = await listLogFiles();
    for (final file in files) {
      await deleteLogFile(file.path);
    }
  }

}
