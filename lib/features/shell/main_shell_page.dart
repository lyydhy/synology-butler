import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/presentation/pages/dashboard_page.dart';
import '../transfers/presentation/pages/transfers_page.dart';
import '../files/presentation/pages/files_page.dart';
import '../settings/presentation/pages/settings_page.dart';
import '../transfers/presentation/providers/transfer_providers.dart';

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
  Widget build(BuildContext context) {
    final activeTransferCount = ref.watch(activeTransferCountProvider);

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
