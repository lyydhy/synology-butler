import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PlatformDownloadsDirectory {
  static const _channel = MethodChannel('syno_keeper/storage');

  static Future<Directory> resolve() async {
    if (Platform.isAndroid) {
      final path = await _channel.invokeMethod<String>('getPublicDownloadsPath');
      if (path != null && path.isNotEmpty) {
        final dir = Directory(path);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return dir;
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/Download');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
