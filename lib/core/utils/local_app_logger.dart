import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalAppLogger {
  static Future<void> log({
    required String level,
    required String module,
    required String event,
    String? message,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final file = await _resolveTodayLogFile();
      await _cleanupOldLogs();

      final buffer = StringBuffer()
        ..writeln('[${DateTime.now().toUtc().toIso8601String()}] [$level] [$module] $event');

      if (message != null && message.isNotEmpty) {
        buffer.writeln(message);
      }

      if (extra != null && extra.isNotEmpty) {
        buffer.writeln('extra:');
        extra.forEach((key, value) {
          buffer.writeln('- $key: $value');
        });
      }

      buffer.writeln('---');

      final text = buffer.toString();
      await file.writeAsString(text, mode: FileMode.append, flush: false);
      debugPrint('[LOCAL_LOG]\n$text');
    } catch (e) {
      debugPrint('[LOCAL_LOG][FAIL] $e');
    }
  }

  static Future<File> _resolveTodayLogFile() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${baseDir.path}/app_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    final now = DateTime.now().toUtc();
    final fileName = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}.txt';
    final file = File('${logsDir.path}/$fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  static Future<void> _cleanupOldLogs() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${baseDir.path}/app_logs');
    if (!await logsDir.exists()) return;

    final files = await logsDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.txt'))
        .cast<File>()
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));

    final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 7));
    for (final file in files) {
      final stat = await file.stat();
      if (stat.modified.toUtc().isBefore(cutoff)) {
        await file.delete();
      }
    }
  }
}
