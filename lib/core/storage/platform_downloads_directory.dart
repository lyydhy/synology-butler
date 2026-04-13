import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class PlatformDownloadsDirectory {
  static const _channel = MethodChannel('syno_keeper/storage');

  static Future<Directory> resolve() async {
    if (Platform.isAndroid) {
      final path = await _channel.invokeMethod<String>('getPublicDownloadsPath');
      if (path != null && path.isNotEmpty) {
        // 确保返回绝对路径
        String absPath = path;
        if (!path.startsWith('/')) {
          // 相对路径，尝试获取外部存储根目录
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            // extDir通常是 /storage/emulated/0/Android/data/com.qunhui.mage/files
            // 需要回退到 /storage/emulated/0/
            final match = RegExp(r'^/storage/emulated/\d+').firstMatch(extDir.path);
            if (match != null) {
              absPath = '${match.group(0)}/$path';
            }
          }
        }
        final dir = Directory(absPath);
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
