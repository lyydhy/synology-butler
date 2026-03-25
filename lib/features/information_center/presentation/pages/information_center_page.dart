import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/information_center_providers.dart';
import '../tabs/network_tab.dart';
import '../tabs/overview_tab.dart';
import '../tabs/storage_tab.dart';

class InformationCenterPage extends ConsumerWidget {
  final String? initialTab;

  const InformationCenterPage({super.key, this.initialTab});

  int _resolveInitialTabIndex() {
    switch (initialTab) {
      case 'network':
        return 1;
      case 'storage':
        return 2;
      case 'overview':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(informationCenterProvider);
    final overviewAsync = ref.watch(dashboardOverviewSafeProvider);

    return DefaultTabController(
      length: 3,
      initialIndex: _resolveInitialTabIndex(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('信息中心'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: () {
                ref.invalidate(informationCenterProvider);
                ref.invalidate(dashboardBaseOverviewProvider);
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '概括'),
              Tab(text: '网络'),
              Tab(text: '存储'),
            ],
          ),
        ),
        body: infoAsync.when(
          data: (info) {
            final overview = overviewAsync.valueOrNull;
            return TabBarView(
              children: [
                OverviewTab(info: info),
                NetworkTab(info: info),
                StorageTab(info: info, overview: overview),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('信息中心加载失败\n$error', textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
