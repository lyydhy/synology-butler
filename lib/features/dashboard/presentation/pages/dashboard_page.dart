import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/realtime_reconnect_bridge.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../core/utils/time_util.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../core/utils/l10n.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../packages/presentation/providers/package_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/dashboard_realtime_global.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with WidgetsBindingObserver {
  DateTime? _lastForegroundRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final now = DateTime.now();
    if (_lastForegroundRefreshAt != null && now.difference(_lastForegroundRefreshAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastForegroundRefreshAt = now;

    final connection = ref.read(currentConnectionProvider);
    if (!connection.hasSession) {
      return;
    }

    // ignore: avoid_print
    print('[Dashboard][Lifecycle] app resumed, refresh base overview + reconnect realtime');
    ref.invalidate(dashboardBaseOverviewProvider);
    final reconnect = RealtimeReconnectBridge.callback;
    if (reconnect != null) {
      unawaited(reconnect());
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final overview = ref.watch(dashboardOverviewSafeProvider);
    final realtimeState = ref.watch(globalRealtimeOverviewProvider);
    final connection = ref.watch(currentConnectionProvider);
    final currentServer = connection.server;
    final currentSession = connection.session;
    final dockerInstalledAsync = ref.watch(dockerFeatureInstalledProvider);

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _HeroCard(
            title: data?.serverName ?? currentServer.name,
            subtitle: _buildSystemVersionText(data),
            connection: ServerUrlHelper.buildBaseUrl(currentServer),
            realtimeText: currentSession.synoToken == null || currentSession.synoToken!.isEmpty
                ? '实时服务准备中'
                : realtimeLoading
                    ? '实时连接中'
                    : realtimeFailed
                        ? '实时重连中'
                        : '实时已连接',
          ),
          const SizedBox(height: 16),
          _AppSection(
            title: l10n.dashboardSectionApps,
            subtitle: l10n.dashboardSectionAppsSubtitle,
            items: [
              if (dockerInstalledAsync.valueOrNull == true)
                _AppEntryItem(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.dashboardContainerManagement,
                  description: l10n.dashboardContainerManagementDesc,
                  color: Colors.blueGrey,
                  onTap: () => context.push('/container-management'),
                ),
              _AppEntryItem(
                icon: Icons.sync_alt_rounded,
                label: l10n.dashboardTransfers,
                description: l10n.dashboardTransfersDesc,
                color: Colors.deepOrange,
                onTap: () => context.push('/transfers'),
              ),
              _AppEntryItem(
                icon: Icons.tune_rounded,
                label: l10n.dashboardControlPanel,
                description: l10n.dashboardControlPanelDesc,
                color: Colors.deepPurple,
                onTap: () => context.push('/control-panel'),
              ),
              _AppEntryItem(
                icon: Icons.info_outline_rounded,
                label: l10n.dashboardInformationCenter,
                description: l10n.dashboardInformationCenterDesc,
                color: Colors.indigo,
                onTap: () => context.push('/information-center'),
              ),
              _AppEntryItem(
                icon: Icons.monitor_heart_outlined,
                label: l10n.dashboardPerformance,
                description: l10n.dashboardPerformanceDesc,
                color: Colors.teal,
                onTap: () => context.push('/performance'),
              ),
            ],
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
          _VolumeSection(volumes: data?.volumes ?? const []),
          const SizedBox(height: 12),
          _UptimeCard(uptimeText: data?.uptimeText),
        ],
      ),
    );
  }

  String _buildSystemVersionText(SystemStatus? data) {
    if (data == null) return '暂未获取到系统版本';

    final version = data.dsmVersion.trim();
    if (version.isEmpty || version == 'DSM --' || version == 'DSM 版本未知') {
      return '暂未获取到系统版本';
    }

    return version;
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '搜索设备、功能或页面',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(label: realtimeText),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.dns_outlined, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      connection,
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppSection extends StatelessWidget {
  const _AppSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<_AppEntryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) => _AppEntryCard(item: items[index]),
          ),
        ],
      ),
    );
  }
}

class _AppEntryItem {
  const _AppEntryItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;
}

class _AppEntryCard extends StatelessWidget {
  const _AppEntryCard({required this.item});

  final _AppEntryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: item.color.withValues(alpha: 0.08),
            border: Border.all(color: item.color.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
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
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
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

class _VolumeSection extends StatelessWidget {
  final List<StorageVolumeStatus> volumes;

  const _VolumeSection({required this.volumes});

  @override
  Widget build(BuildContext context) {
    if (volumes.isEmpty) {
      return SummaryCard(
        title: l10n.dashboardStorage,
        subtitle: l10n.dashboardStorageEmpty,
        trailing: const Icon(Icons.storage_rounded),
        onTap: () => context.push('/information-center?tab=storage'),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/information-center?tab=storage'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.dashboardStorage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 14),
            ...volumes.asMap().entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == volumes.length - 1 ? 0 : 14),
                child: _VolumeUsageTile(
                  volume: entry.value,
                  index: entry.key,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeUsageTile extends StatelessWidget {
  final StorageVolumeStatus volume;
  final int index;

  const _VolumeUsageTile({
    required this.volume,
    required this.index,
  });

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

  String _buildDisplayName() {
    final raw = volume.name.trim();
    if (raw.isEmpty) return l10n.storageLabelN(index + 1);

    final match = RegExp(r'^volume\s*(\d+)$', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      return l10n.storageLabelN(match.group(1)!);
    }

    if (raw.toLowerCase().startsWith('volume')) {
      return l10n.storageLabelN(index + 1);
    }

    return raw;
  }

  String _buildUsageDetail() {
    final used = volume.usedBytes;
    final total = volume.totalBytes;

    if (used != null && used > 0 && total != null && total > 0) {
      return l10n.usedSlashTotal(_formatBytes(used), _formatBytes(total));
    }

    if (used != null && used > 0) {
      return l10n.usedSlashUnknown(_formatBytes(used));
    }

    if (total != null && total > 0) {
      return l10n.unknownSlashTotal(_formatBytes(total));
    }

    return l10n.usedUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final usage = volume.usage.isNaN ? 0.0 : volume.usage;
    final ratio = (usage / 100).clamp(0.0, 1.0);
    final displayName = _buildDisplayName();
    final usageDetail = _buildUsageDetail();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${usage.toStringAsFixed(0)}%',
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
          usageDetail,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ],
    );
  }
}

class _UptimeCard extends StatefulWidget {
  final String? uptimeText;

  const _UptimeCard({required this.uptimeText});

  @override
  State<_UptimeCard> createState() => _UptimeCardState();
}

class _UptimeCardState extends State<_UptimeCard> {
  Timer? _timer;
  Duration? _baseDuration;
  DateTime? _baseTime;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _UptimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uptimeText != widget.uptimeText) {
      _syncFromWidget();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncFromWidget() {
    _timer?.cancel();
    _baseDuration = _parseUptime(widget.uptimeText);
    _baseTime = _baseDuration == null ? null : DateTime.now();

    if (_baseDuration != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Duration? _parseUptime(String? text) {
    if (text == null) return null;
    final value = text.trim();
    if (value.isEmpty) return null;

    final match = RegExp(r'^(?:(\d+):)?(\d{1,2}):(\d{1,2})$').firstMatch(value);
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }

    return null;
  }


  @override
  Widget build(BuildContext context) {
    String subtitle = l10n.notAvailableYet;

    if (_baseDuration != null && _baseTime != null) {
      final current = _baseDuration! + DateTime.now().difference(_baseTime!);
      subtitle = parseTimeStr(current);
    } else if (widget.uptimeText != null && widget.uptimeText!.trim().isNotEmpty) {
      subtitle = widget.uptimeText!.trim();
    }

    return SummaryCard(
      title: l10n.dashboardUptime,
      subtitle: subtitle,
      trailing: const Icon(Icons.schedule_outlined),
    );
  }
}
