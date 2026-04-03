import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 全局 Toast 工具类
/// 
/// 用于显示纯文字提示消息，替代 SnackBar
class Toast {
  /// 显示普通提示
  static void show(String message, {Duration duration = const Duration(seconds: 2)}) {
    BotToast.showText(
      text: message,
      duration: duration,
    );
  }

  /// 显示成功提示
  static void success(String message, {Duration duration = const Duration(seconds: 2)}) {
    BotToast.showText(
      text: '✓ $message',
      duration: duration,
      contentColor: Colors.green,
    );
  }

  /// 显示错误提示
  static void error(String message, {Duration duration = const Duration(seconds: 3)}) {
    BotToast.showText(
      text: '✗ $message',
      duration: duration,
      contentColor: Colors.red,
    );
  }

  /// 显示警告提示
  static void warning(String message, {Duration duration = const Duration(seconds: 2)}) {
    BotToast.showText(
      text: '⚠ $message',
      duration: duration,
      contentColor: Colors.orange,
    );
  }
}
