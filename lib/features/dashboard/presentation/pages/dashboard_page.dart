import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
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
    final overview = ref.watch(dashboardOverviewProvider);
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: overview.when(
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SummaryCard(
              title: data.serverName,
              subtitle: 'DSM ${data.dsmVersion}',
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
                  : '${l10n.sidEstablished} · Realtime connected',
              trailing: const Icon(Icons.verified_user_outlined),
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: l10n.deviceInfo,
              subtitle: 'Model: ${data.modelName ?? l10n.unknown}\nSN: ${data.serialNumber ?? l10n.unknown}',
              trailing: const Icon(Icons.memory_outlined),
            ),
            const SizedBox(height: 12),
            SummaryCard(
              title: l10n.uptime,
              subtitle: data.uptimeText ?? l10n.notAvailableYet,
              trailing: const Icon(Icons.schedule_outlined),
            ),
            const SizedBox(height: 12),
            _MetricCard(title: l10n.cpu, value: '${data.cpuUsage.toStringAsFixed(0)}%'),
            _MetricCard(title: l10n.memory, value: '${data.memoryUsage.toStringAsFixed(0)}%'),
            _MetricCard(title: l10n.storage, value: '${data.storageUsage.toStringAsFixed(0)}%'),
          ],
        ),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            Text('加载首页失败：${ErrorMapper.map(error).message}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(dashboardOverviewProvider),
              child: const Text('重试'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
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
