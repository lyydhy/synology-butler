import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/nas_server.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/container_management/presentation/pages/compose_project_build_logs_page.dart';
import '../features/container_management/presentation/pages/compose_project_create_page.dart';
import '../features/container_management/presentation/pages/compose_project_detail_page.dart';
import '../features/container_management/presentation/pages/container_detail_page.dart';
import '../features/container_management/presentation/pages/container_management_page.dart';
import '../features/container_management/presentation/pages/container_management_settings_page.dart';
import '../features/settings/presentation/pages/sharing_links_page.dart';
import '../features/settings/presentation/pages/about_page.dart';
import '../features/control_panel/presentation/pages/control_panel_page.dart';
import '../features/debug/presentation/pages/app_logs_page.dart';
import '../features/debug/presentation/pages/debug_info_page.dart';
import '../features/diagnostics/presentation/pages/diagnostics_page.dart';
import '../features/external_access/presentation/pages/external_access_page.dart';
import '../features/external_devices/presentation/pages/external_devices_page.dart';
import '../features/file_services/presentation/pages/file_services_page.dart';
import '../features/network/presentation/pages/network_page.dart';
import '../features/shared_folders/presentation/pages/shared_folders_page.dart';
import '../features/user_groups/presentation/pages/user_groups_page.dart';
import '../features/external_share/models/shared_incoming_file.dart';
import '../features/external_share/pages/external_file_upload_page.dart';
import '../features/files/presentation/pages/files_page.dart';
import '../features/files/presentation/pages/image_preview_page.dart';
import '../features/files/presentation/pages/text_editor_page.dart';
import '../features/files/presentation/pages/text_preview_page.dart';
import '../features/files/presentation/pages/share_link_page.dart';
import '../features/files/presentation/pages/video_preview_page.dart';
import '../features/index_service/presentation/pages/index_service_page.dart';
import '../features/information_center/presentation/pages/information_center_page.dart';
import '../features/apps/presentation/pages/apps_page.dart';
import '../features/packages/presentation/pages/package_detail_page.dart';
import '../features/packages/presentation/pages/packages_page.dart';
import '../features/performance/presentation/pages/performance_page.dart';
import '../features/power/presentation/pages/power_page.dart';
import '../features/server-management/presentation/pages/server_management_page.dart';
import '../features/shell/main_shell_page.dart';
import '../features/task_scheduler/presentation/pages/task_scheduler_page.dart';
import '../features/terminal/presentation/pages/terminal_page.dart';
import '../features/transfers/presentation/pages/transfers_page.dart';
import '../features/downloads/presentation/pages/downloads_page.dart';
import '../features/upgrade/presentation/pages/upgrade_page.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: initialLocation,
    routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => LoginPage(initialServer: state.extra as NasServer?)),
    GoRoute(path: '/home', builder: (context, state) => const MainShellPage()),
    GoRoute(path: '/servers', builder: (context, state) => const ServerManagementPage()),
    GoRoute(path: '/debug', builder: (context, state) => const DebugInfoPage()),
    GoRoute(path: '/app-logs', builder: (context, state) => const AppLogsPage()),
    GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
    GoRoute(path: '/sharing-links', builder: (context, state) => const SharingLinksPage()),
    GoRoute(path: '/diagnostics', builder: (context, state) => const DiagnosticsPage()),
    GoRoute(path: '/transfers', builder: (context, state) => const TransfersPage()),
    GoRoute(path: '/downloads', builder: (context, state) => const DownloadsPage()),
    GoRoute(path: '/external-access', builder: (context, state) => const ExternalAccessPage()),
    GoRoute(path: '/index-service', builder: (context, state) => const IndexServicePage()),
    GoRoute(path: '/task-scheduler', builder: (context, state) => const TaskSchedulerPage()),
    GoRoute(path: '/external-devices', builder: (context, state) => const ExternalDevicesPage()),
    GoRoute(path: '/shared-folders', builder: (context, state) => const SharedFoldersPage()),
    GoRoute(path: '/user-groups', builder: (context, state) => const UserGroupsPage()),
    GoRoute(path: '/file-services', builder: (context, state) => const FileServicesPage()),
    GoRoute(path: '/network', builder: (context, state) => const NetworkPage()),
    GoRoute(path: '/terminal', builder: (context, state) => const TerminalPage()),
    GoRoute(path: '/power', builder: (context, state) => const PowerPage()),
    GoRoute(path: '/upgrade', builder: (context, state) => const UpgradePage()),
    GoRoute(path: '/packages', builder: (context, state) => const PackagesPage()),
    GoRoute(path: '/apps', builder: (context, state) => const AppsPage()),
    GoRoute(path: '/performance', builder: (context, state) => const PerformancePage()),
    GoRoute(path: '/container-management', builder: (context, state) => const ContainerManagementPage()),
    GoRoute(path: '/control-panel', builder: (context, state) => const ControlPanelPage()),
    GoRoute(
      path: '/container-management/settings',
      builder: (context, state) => const ContainerManagementSettingsPage(),
    ),
    GoRoute(
      path: '/container-management/detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        final name = extra['name']?.toString() ?? '';
        if (name.isEmpty) {
          return const Scaffold(body: Center(child: Text('容器详情参数缺失')));
        }
        return ContainerDetailPage(name: name);
      },
    ),
    GoRoute(path: '/container-management/compose-create', builder: (context, state) => const ComposeProjectCreatePage()),
    GoRoute(
      path: '/container-management/compose-detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        final id = extra['id']?.toString() ?? '';
        final name = extra['name']?.toString() ?? '';
        if (id.isEmpty) {
          return const Scaffold(body: Center(child: Text('Compose 项目详情参数缺失')));
        }
        return ComposeProjectDetailPage(id: id, name: name.isEmpty ? 'Compose 项目' : name);
      },
    ),
    GoRoute(
      path: '/container-management/compose-build-logs',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        final id = extra['id']?.toString() ?? '';
        final name = extra['name']?.toString() ?? '';
        final mode = extra['mode']?.toString() ?? 'build';
        if (id.isEmpty) {
          return const Scaffold(body: Center(child: Text('Compose 构建日志参数缺失')));
        }
        return ComposeProjectBuildLogsPage(
          id: id,
          name: name.isEmpty ? 'Compose 项目' : name,
          mode: mode,
        );
      },
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
          sid: extra['sid']?.toString(),
          cookieHeader: extra['cookieHeader']?.toString(),
          synoToken: extra['synoToken']?.toString(),
        );
      },
    ),
    GoRoute(
      path: '/share-link',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const {};
        return ShareLinkPage(
          path: extra['path']?.toString() ?? '/',
        );
      },
    ),
    ],
  );
}
