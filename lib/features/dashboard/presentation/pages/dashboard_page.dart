import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/server_url_helper.dart';
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
    final realtimeState = ref.watch(dashboardOverviewProvider);
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
          SummaryCard(
            title: currentServer.name,
            subtitle: data == null ? 'DSM --' : 'DSM ${data.dsmVersion}',
            trailing: const Icon(Icons.dns_outlined),
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: l10n.currentConnection,
            subtitle: ServerUrlHelper.buildBaseUrl(currentServer),
            trailing: Text(l10n.online),
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: l10n.sessionStatus,
            subtitle: currentSession.synoToken == null || currentSession.synoToken!.isEmpty
                ? '${l10n.sidEstablished} · SynoToken missing'
                : realtimeFailed
                    ? '${l10n.sidEstablished} · Realtime failed'
                    : realtimeLoading
                        ? '${l10n.sidEstablished} · Realtime connecting'
                        : '${l10n.sidEstablished} · Realtime connected',
            trailing: const Icon(Icons.verified_user_outlined),
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: l10n.deviceInfo,
            subtitle: 'Model: ${data?.modelName ?? l10n.unknown}\nSN: ${data?.serialNumber ?? l10n.unknown}',
            trailing: const Icon(Icons.memory_outlined),
          ),
          const SizedBox(height: 12),
          SummaryCard(
            title: l10n.uptime,
            subtitle: data?.uptimeText ?? l10n.notAvailableYet,
            trailing: const Icon(Icons.schedule_outlined),
          ),
          const SizedBox(height: 12),
          _MetricCard(title: l10n.cpu, value: data == null ? '--' : '${data.cpuUsage.toStringAsFixed(0)}%'),
          _MetricCard(title: l10n.memory, value: data == null ? '--' : '${data.memoryUsage.toStringAsFixed(0)}%'),
          _MetricCard(title: l10n.storage, value: data == null ? '--' : '${data.storageUsage.toStringAsFixed(0)}%'),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
