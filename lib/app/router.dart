import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/debug/presentation/pages/debug_info_page.dart';
import '../features/diagnostics/presentation/pages/diagnostics_page.dart';
import '../features/server-management/presentation/pages/server_management_page.dart';
import '../features/shell/main_shell_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const MainShellPage()),
    GoRoute(path: '/servers', builder: (context, state) => const ServerManagementPage()),
    GoRoute(path: '/debug', builder: (context, state) => const DebugInfoPage()),
    GoRoute(path: '/diagnostics', builder: (context, state) => const DiagnosticsPage()),
  ],
);
