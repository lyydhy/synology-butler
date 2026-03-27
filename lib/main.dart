import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/startup_session_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupGate = StartupSessionGate();
  final startupResult = await startupGate.resolve();

  runApp(
    ProviderScope(
      child: QunhuiManagerApp(initialLocation: startupResult.initialLocation),
    ),
  );
}
