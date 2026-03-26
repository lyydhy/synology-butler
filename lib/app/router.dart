import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/container_management/presentation/pages/container_management_page.dart';
import '../features/container_management/presentation/pages/container_management_settings_page.dart';
import '../features/debug/presentation/pages/app_logs_page.dart';
import '../features/debug/presentation/pages/debug_info_page.dart';
import '../features/diagnostics/presentation/pages/diagnostics_page.dart';
import '../features/external_share/models/shared_incoming_file.dart';
import '../features/external_share/pages/external_file_upload_page.dart';
import '../features/files/presentation/pages/files_page.dart';
import '../features/files/presentation/pages/image_preview_page.dart';
import '../features/files/presentation/pages/text_editor_page.dart';
import '../features/files/presentation/pages/text_preview_page.dart';
import '../features/files/presentation/pages/video_preview_page.dart';
import '../features/information_center/presentation/pages/information_center_page.dart';
import '../features/packages/presentation/pages/package_detail_page.dart';
import '../features/packages/presentation/pages/packages_page.dart';
import '../features/performance/presentation/pages/performance_page.dart';
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
    GoRoute(path: '/app-logs', builder: (context, state) => const AppLogsPage()),
    GoRoute(path: '/diagnostics', builder: (context, state) => const DiagnosticsPage()),
    GoRoute(path: '/transfers', builder: (context, state) => const TransfersPage()),
    GoRoute(path: '/packages', builder: (context, state) => const PackagesPage()),
    GoRoute(path: '/performance', builder: (context, state) => const PerformancePage()),
    GoRoute(path: '/container-management', builder: (context, state) => const ContainerManagementPage()),
    GoRoute(
      path: '/container-management/settings',
      builder: (context, state) => const ContainerManagementSettingsPage(),
    ),
    GoRoute(
      path: '/files/pick-directory',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return FilesPage(
          directoryPickerMode: true,
          initialPath: extra['initialPath']?.toString() ?? '/',
        );
      },
    ),
    GoRoute(
      path: '/external-upload',
      builder: (context, state) {
        final file = state.extra as SharedIncomingFile?;
        if (file == null) {
          return const Scaffold(body: Center(child: Text('外部上传参数缺失')));
        }
        return ExternalFileUploadPage(file: file);
      },
    ),
    GoRoute(
      path: '/information-center',
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        return InformationCenterPage(initialTab: tab);
      },
    ),
    GoRoute(
      path: '/packages/detail',
      builder: (context, state) {
        final extra = state.extra;
        if (extra == null) {
          return const Scaffold(body: Center(child: Text('套件详情参数缺失')));
        }
        return PackageDetailPage(item: extra as dynamic);
      },
    ),
    GoRoute(
      path: '/text-preview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return TextPreviewPage(
          path: extra['path']?.toString() ?? '',
          name: extra['name']?.toString() ?? '文本预览',
        );
      },
    ),
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
    GoRoute(
      path: '/image-preview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return ImagePreviewPage(
          path: extra['path']?.toString() ?? '',
          name: extra['name']?.toString() ?? '图片预览',
        );
      },
    ),
    GoRoute(
      path: '/video-preview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return VideoPreviewPage(
          baseUrl: extra['baseUrl']?.toString() ?? '',
          path: extra['path']?.toString() ?? '',
          name: extra['name']?.toString() ?? '视频预览',
          synoToken: extra['synoToken']?.toString(),
        );
      },
    ),
  ],
);
