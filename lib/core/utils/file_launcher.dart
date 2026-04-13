import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

class FileLauncher {
  /// 打开文件
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

  /// 打开包含文件的目录（尝试打开文件管理器并定位到该目录）
  /// - Android: 通过 open_filex 打开目录
  /// - iOS: 不支持，返回 false
  static Future<bool> openDirectory(String path) async {
    if (kIsWeb) return false;

    final directory = Directory(path);
    if (!await directory.exists()) {
      throw Exception('目录不存在：$path');
    }

    // open_filex 不直接支持打开目录，尝试用文件方式打开
    final result = await OpenFilex.open(path);
    // on Android this may work if a file manager handles directory URIs
    // on iOS this will likely fail - return false to indicate unsupported
    if (result.type == ResultType.done) {
      return true;
    }
    // open_filex 无法打开目录，返回 false 让调用方处理
    return false;
  }

  /// 检查平台是否支持打开目录
  static bool get supportsOpenDirectory {
    if (kIsWeb) return false;
    // open_filex 在 iOS 上无法打开目录
    return !Platform.isIOS;
  }
}
