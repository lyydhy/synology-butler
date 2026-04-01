import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/startup_session_gate.dart';
import 'core/services/download_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化下载通知服务
  await DownloadNotificationService().initialize();
  
  final startupGate = StartupSessionGate();
  final startupResult = await startupGate.resolve();

  runApp(
    ProviderScope(
      child: QunhuiManagerApp(initialLocation: startupResult.initialLocation),
    ),
  );
}
