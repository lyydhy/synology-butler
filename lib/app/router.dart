import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/debug/presentation/pages/debug_info_page.dart';
import '../features/diagnostics/presentation/pages/diagnostics_page.dart';
import '../features/files/presentation/pages/text_editor_page.dart';
import '../features/server-management/presentation/pages/server_management_page.dart';
import '../features/shell/main_shell_page.dart';
import '../features/transfers/presentation/pages/transfers_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const MainShellPage()),
    GoRoute(path: '/servers', builder: (context, state) => const ServerManagementPage()),
    GoRoute(path: '/debug', builder: (context, state) => const DebugInfoPage()),
    GoRoute(path: '/diagnostics', builder: (context, state) => const DiagnosticsPage()),
    GoRoute(path: '/transfers', builder: (context, state) => const TransfersPage()),
    GoRoute(
      path: '/text-editor',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return TextEditorPage(
          path: extra['path']?.toString() ?? '',
          name: extra['name']?.toString() ?? '文本编辑器',
        );
      },
    ),
  ],
);
