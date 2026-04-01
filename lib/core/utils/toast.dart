import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

/// 简单的文本提示 Toast，无操作按钮
void showToast(String message, {Duration duration = const Duration(seconds: 2)}) {
  BotToast.showText(
    text: message,
    duration: duration,
    contentColor: Colors.black87,
    textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    borderRadius: BorderRadius.circular(8),
  );
}

/// 成功提示
void showSuccessToast(String message) {
  BotToast.showText(
    text: '✓ $message',
    duration: const Duration(seconds: 2),
    contentColor: Colors.green.shade700,
    textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    borderRadius: BorderRadius.circular(8),
  );
}

/// 错误提示
void showErrorToast(String message) {
  BotToast.showText(
    text: '✗ $message',
    duration: const Duration(seconds: 3),
    contentColor: Colors.red.shade700,
    textStyle: const TextStyle(color: Colors.white, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    borderRadius: BorderRadius.circular(8),
  );
}
