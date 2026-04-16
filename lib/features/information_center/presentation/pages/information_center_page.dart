import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/providers/global_home_provider.dart';
import '../providers/information_center_providers.dart';
import '../tabs/network_tab.dart';
import '../tabs/overview_tab.dart';
import '../tabs/storage_tab.dart';

class InformationCenterPage extends ConsumerStatefulWidget {
  final String? initialTab;

  const InformationCenterPage({super.key, this.initialTab});

  @override
  ConsumerState<InformationCenterPage> createState() => _InformationCenterPageState();
}

class _InformationCenterPageState extends ConsumerState<InformationCenterPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: _resolveInitialTabIndex());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _resolveInitialTabIndex() {
    switch (widget.initialTab) {
      case 'network':
        return 1;
      case 'storage':
        return 2;
      default:
        return 0;
    }
  }

  void _refresh() {
    ref.invalidate(informationCenterProvider);
    ref.invalidate(globalHomeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(informationCenterProvider);
    final overviewAsync = ref.watch(dashboardOverviewSafeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('信息中心'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              height: 54,
              iconSize: 18,
              fontSize: 13,
              tabs: const [
                SlidingTabItem(icon: Icons.info_outline_rounded, label: '概括'),
                SlidingTabItem(icon: Icons.lan_outlined, label: '网络'),
                SlidingTabItem(icon: Icons.storage_rounded, label: '存储'),
              ],
            ),
          ),
        ),
      ),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _InformationCenterErrorView(error: e, onRetry: _refresh),
        data: (info) {
          final overview = overviewAsync.valueOrNull;
          return TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(info: info),
              NetworkTab(info: info),
              StorageTab(info: info, overview: overview),
            ],
          );
        },
      ),
    );
  }
}

class _InformationCenterErrorView extends StatelessWidget {
  const _InformationCenterErrorView({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: '信息中心加载失败',
      message: '$error',
      onRetry: onRetry,
      actionLabel: '重新加载',
    );
  }
}
