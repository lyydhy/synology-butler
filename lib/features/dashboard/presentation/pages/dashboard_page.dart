import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(dashboardOverviewSafeProvider);
    final realtimeState = ref.watch(dashboardRealtimeOverviewProvider);
    final currentServer = ref.watch(currentServerProvider);
    final currentSession = ref.watch(currentSessionProvider);

    if (currentServer == null || currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 12),
                Text(l10n.noSessionPleaseLogin),
              ],
            ),
          ),
        ),
      );
    }

    final data = overview.valueOrNull;
    final realtimeFailed = realtimeState.hasError;
    final realtimeLoading = realtimeState.isLoading;

    if (realtimeFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          const SnackBar(content: Text('实时监控连接失败，已降级显示页面，其它功能不受影响')),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(
            title: data?.serverName ?? currentServer.name,
            subtitle: data == null ? 'DSM --' : 'DSM ${data.dsmVersion}',
            connection: ServerUrlHelper.buildBaseUrl(currentServer),
            realtimeText: currentSession.synoToken == null || currentSession.synoToken!.isEmpty
                ? 'SynoToken missing'
                : realtimeFailed
                    ? 'Realtime failed'
                    : realtimeLoading
                        ? 'Realtime connecting'
                        : 'Realtime connected',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: l10n.cpu,
                  value: data == null ? '--' : '${data.cpuUsage.toStringAsFixed(0)}%',
                  icon: Icons.memory_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: l10n.memory,
                  value: data == null ? '--' : '${data.memoryUsage.toStringAsFixed(0)}%',
                  icon: Icons.developer_board_outlined,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: l10n.storage,
            value: data == null ? '--' : '${data.storageUsage.toStringAsFixed(0)}%',
            icon: Icons.storage_rounded,
            color: Colors.orange,
          ),
          if (data != null && data.volumes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SummaryCard(
              title: '存储空间',
              subtitle: data.volumes.map((v) => '${v.name} · ${v.usage.toStringAsFixed(0)}%').join('\n'),
              trailing: const Icon(Icons.dns_outlined),
            ),
          ],
          const SizedBox(height: 12),
          SummaryCard(
            title: l10n.deviceInfo,
            subtitle: 'Model: ${data?.modelName ?? l10n.unknown}\nSN: ${data?.serialNumber ?? l10n.unknown}',
            trailing: const Icon(Icons.devices_other_outlined),
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: l10n.uptime,
            subtitle: data?.uptimeText ?? l10n.notAvailableYet,
            trailing: const Icon(Icons.schedule_outlined),
          ),
          if (realtimeFailed) ...[
            const SizedBox(height: 12),
            const Text(
              '实时资源监控当前连接失败，页面已降级显示。请查看控制台日志继续排查 websocket / cookie / socket.io 握手。',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String connection;
  final String realtimeText;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.connection,
    required this.realtimeText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.dns_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(connection, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(realtimeText, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
