import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_state.dart';
import '../providers/external_access_providers.dart';

class ExternalAccessPage extends ConsumerWidget {
  const ExternalAccessPage({super.key});

  static const _statusMap = {
    'service_ddns_normal': ('正常', Colors.green),
    'service_ddns_error_unknown': ('联机失败', Colors.red),
    'loading': ('加载中', Colors.blue),
    'disabled': ('已停用', Colors.grey),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(externalAccessProvider);
    final refreshing = ref.watch(ddnsRefreshControllerProvider);

    Future<void> refreshAll() => ref.read(refreshDdnsProvider)(recordId: null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('外部访问'),
        actions: [
          IconButton(
            tooltip: '刷新 DDNS',
            onPressed: refreshing ? null : refreshAll,
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '外部访问加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(externalAccessProvider),
          actionLabel: '重新加载',
        ),
        data: (data) {
          if (data.records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public_off_outlined, size: 52),
                    SizedBox(height: 12),
                    Text('当前没有 DDNS 记录'),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if ((data.nextUpdateTime ?? '').isNotEmpty)
                _SummaryCard(nextUpdateTime: data.nextUpdateTime!),
              ...data.records.map(
                (record) {
                  final status = _statusMap[record.status] ?? (record.status, Colors.orange);
                  return _RecordCard(
                    provider: record.provider,
                    hostname: record.hostname,
                    ip: record.ip,
                    lastUpdated: record.lastUpdated,
                    statusText: status.$1,
                    statusColor: status.$2,
                    refreshing: refreshing,
                    onRefresh: () => ref.read(refreshDdnsProvider)(recordId: record.id),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String nextUpdateTime;

  const _SummaryCard({required this.nextUpdateTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded),
          const SizedBox(width: 12),
          Expanded(child: Text('下次自动更新时间：$nextUpdateTime')),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final String provider;
  final String hostname;
  final String ip;
  final String lastUpdated;
  final String statusText;
  final Color statusColor;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _RecordCard({
    required this.provider,
    required this.hostname,
    required this.ip,
    required this.lastUpdated,
    required this.statusText,
    required this.statusColor,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(provider, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusText, style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(hostname, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('IP：$ip'),
          const SizedBox(height: 4),
          Text('上次更新：${lastUpdated.isEmpty ? '-' : lastUpdated}'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: refreshing ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('立即刷新'),
            ),
          ),
        ],
      ),
    );
  }
}
