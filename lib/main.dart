import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/startup_session_gate.dart';
import 'core/services/transfer_notification_service.dart';
import 'core/utils/global_error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化传输通知服务（上传/下载）
  final notificationService = TransferNotificationService();
  await notificationService.initialize();

  // 请求通知权限（Android 13+）
  await notificationService.requestPermission();

  final startupGate = StartupSessionGate();
  final startupResult = await startupGate.resolve();

  // 全局错误处理必须在 runApp 之前注册
  registerGlobalErrorHandlers();

  runApp(
    ProviderScope(
      child: QunhuiManagerApp(initialLocation: startupResult.initialLocation),
    ),
  );
}
