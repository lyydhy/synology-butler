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
        body: Builder(
          builder: (context) {
            final overview = overviewAsync.valueOrNull;

            if (infoAsync.isLoading) {
              return TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(3, (_) => const _InformationCenterLoadingView()),
              );
            }

            if (infoAsync.hasError) {
              return TabBarView(
                children: List.generate(
                  3,
                  (_) => _InformationCenterErrorView(
                    error: infoAsync.error,
                    onRetry: () {
                      ref.invalidate(informationCenterProvider);
                      ref.invalidate(dashboardBaseOverviewProvider);
                    },
                  ),
                ),
              );
            }

            final info = infoAsync.requireValue;
            return TabBarView(
              children: [
                OverviewTab(info: info),
                NetworkTab(info: info),
                StorageTab(info: info, overview: overview),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InformationCenterLoadingView extends StatelessWidget {
  const _InformationCenterLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _InformationCenterErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _InformationCenterErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            const Text('信息中心加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}
