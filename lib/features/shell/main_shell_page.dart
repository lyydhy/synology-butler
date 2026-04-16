import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/presentation/pages/dashboard_page.dart';
import '../dashboard/presentation/providers/dashboard_realtime_global.dart';
import '../dashboard/presentation/providers/global_home_provider.dart';
import '../transfers/presentation/pages/transfers_page.dart';
import '../files/presentation/pages/files_page.dart';
import '../files/presentation/providers/file_providers.dart';
import '../settings/presentation/pages/settings_page.dart';
import '../transfers/presentation/providers/transfer_providers.dart';
import '../../../domain/entities/transfer_task.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  int currentIndex = 0;

  final pages = const [
    DashboardPage(),
    FilesPage(),
    TransfersPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 登录后进入 main_shell，重置文件浏览路径到根目录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentFilePathProvider.notifier).state = '/';
    });
  }

  @override
  Widget build(BuildContext context) {
    // 触发 HTTP 请求 A+B，连接 WS（登录后生效）
    ref.watch(globalHomeProvider);
    ref.watch(globalRealtimeOverviewProvider);

    final activeTransferCount = ref.watch(transferProvider).where((t) => t.status == TransferTaskStatus.queued || t.status == TransferTaskStatus.running).length;

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: '首页',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: '文件',
          ),
          NavigationDestination(
            icon: _buildDownloadIcon(activeTransferCount),
            label: '下载',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadIcon(int count) {
    if (count == 0) {
      return const Icon(Icons.download_outlined);
    }
    return Badge(
      label: count > 99 ? const Text('99+') : Text('$count'),
      child: const Icon(Icons.download_outlined),
    );
  }
}
