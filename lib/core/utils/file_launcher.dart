import 'dart:io';

import 'package:open_filex/open_filex.dart';

class FileLauncher {
  static Future<void> open(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('文件不存在：$path');
    }

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw Exception(result.message.isEmpty ? '无法打开文件' : result.message);
    }
  }
}
