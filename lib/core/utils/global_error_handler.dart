import 'package:flutter/foundation.dart';

import 'local_app_logger.dart';

/// 全局错误处理器
/// 在 main() 中调用 registerGlobalErrorHandlers() 即可
void registerGlobalErrorHandlers() {
  // 1. Flutter 框架级错误（widget 构建、渲染、类型转换等）
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // 避免递归

    final message = details.exceptionAsString();
    if (_isNoiseError(message)) return;

    final stack = details.stack ?? StackTrace.current;
    final errorType = message.split('\n').first.split(':').first;

    _logError(
      level: 'error',
      module: 'flutter',
      event: 'framework_error',
      message: '[FlutterError] ${details.library ?? 'unknown'}: $message',
      extra: {
        'library': details.library ?? 'unknown',
        'silent': details.silent,
        'errorType': errorType,
      },
      stack: stack,
    );

    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.library ?? 'unknown'}: $message');
    }
  };

  // 2. Dart 异步未捕获错误兜底（Zone 内未处理、Future 拒绝等）
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final errorMessage = error.toString();
    if (_isNoiseError(errorMessage)) return true;

    _logError(
      level: 'error',
      module: 'app',
      event: 'unhandled_async_error',
      message: '[AsyncError] ${error.runtimeType}: $errorMessage\n$stack',
      extra: {'errorType': error.runtimeType.toString()},
      stack: stack,
    );

    if (kDebugMode) {
      debugPrint('[AsyncError] ${error.runtimeType}: $errorMessage');
    }
    return true; // 已处理，不向上传播
  };
}

/// 同步安全记录（使用 Fire-and-forget）
void _logError({
  required String level,
  required String module,
  required String event,
  required String message,
  Map<String, dynamic>? extra,
  StackTrace? stack,
}) {
  try {
    // 异步写入，不阻塞主线程
    LocalAppLogger.log(
      level: level,
      module: module,
      event: event,
      message: stack != null ? '$message\n$stack' : message,
      extra: extra,
    );
  } catch (_) {
    // 记录失败静默忽略，避免递归
  }
}

/// 过滤 Flutter/Dart 内部框架产生的噪音错误
bool _isNoiseError(String message) {
  const noisePatterns = [
    'Bad state: Future already completed',
    'Looking up a deactivated widget',
    'Tried to send a platform message',
    'SocketException: Failed host lookup',
    'HandshakeException',
  ];
  for (final p in noisePatterns) {
    if (message.contains(p)) return true;
  }
  return false;
}

// ─── 类型转换错误辅助 ────────────────────────────────────────────────────────

/// 包装可能抛出 TypeError 的 API 解析代码，自动捕获并记录日志
/// 使用方式: final value = tryParseType<T>(() => json['field'] as T, 'MyAPI.field');
T? tryParseType<T>(T? Function() block, String context) {
  try {
    return block();
  } on TypeError catch (e, stack) {
    _logError(
      level: 'error',
      module: 'app',
      event: 'type_conversion_error',
      message: '[TypeError] $e\n$stack',
      extra: {'context': context},
      stack: stack,
    );
    return null;
  }
}

/// 包装可能抛出异常的异步代码块
Future<T?> tryCatch<T>(
  Future<T> Function() block,
  String context, {
  bool logError = true,
  bool doRethrow = false,
}) async {
  try {
    return await block();
  } catch (e, stack) {
    if (logError) {
      _logError(
        level: 'error',
        module: 'app',
        event: 'async_error',
        message: '[$context] ${e.runtimeType}: $e\n$stack',
        extra: {'context': context, 'errorType': e.runtimeType.toString()},
        stack: stack,
      );
    }
    if (doRethrow) rethrow;
    return null;
  }
}

/// 同步版本
T? tryCatchSync<T>(
  T Function() block,
  String context, {
  bool logError = true,
  bool doRethrow = false,
}) {
  try {
    return block();
  } catch (e, stack) {
    if (logError) {
      _logError(
        level: 'error',
        module: 'app',
        event: 'sync_error',
        message: '[$context] ${e.runtimeType}: $e\n$stack',
        extra: {'context': context, 'errorType': e.runtimeType.toString()},
        stack: stack,
      );
    }
    if (doRethrow) rethrow;
    return null;
  }
}
