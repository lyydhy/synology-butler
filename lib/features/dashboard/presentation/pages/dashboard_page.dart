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
            subtitle: data == null ? 'DSM --' : data.dsmVersion,
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
          _VersionInfoCard(data: data),
          const SizedBox(height: 12),
          _VolumeSection(volumes: data?.volumes ?? const []),
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

class _VersionInfoCard extends StatelessWidget {
  final SystemStatus? data;

  const _VersionInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SummaryCard(
      title: '系统版本',
      subtitle: data?.dsmVersion ?? '暂未获取到版本信息',
      trailing: const Icon(Icons.info_outline_rounded),
    );
  }
}

class _VolumeSection extends StatelessWidget {
  final List<StorageVolumeStatus> volumes;

  const _VolumeSection({required this.volumes});

  @override
  Widget build(BuildContext context) {
    if (volumes.isEmpty) {
      return const SummaryCard(
        title: '存储空间',
        subtitle: '暂未获取到存储空间信息',
        trailing: Icon(Icons.storage_rounded),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded),
              const SizedBox(width: 10),
              Text(
                '存储空间',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...volumes.map(
            (volume) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _VolumeUsageTile(volume: volume),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeUsageTile extends StatelessWidget {
  final StorageVolumeStatus volume;

  const _VolumeUsageTile({required this.volume});

  String _formatBytes(double? value) {
    if (value == null || value <= 0) return '--';

    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (volume.usage / 100).clamp(0.0, 1.0);
    final usedText = _formatBytes(volume.usedBytes);
    final totalText = _formatBytes(volume.totalBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                volume.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${volume.usage.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          (usedText == '--' || totalText == '--') ? '使用情况：${volume.usage.toStringAsFixed(0)}%' : '已用 $usedText / 总计 $totalText',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ],
    );
  }
}
