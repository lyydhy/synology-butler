import 'dart:async';

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
            subtitle: _buildSystemVersionText(data),
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
          _VolumeSection(volumes: data?.volumes ?? const []),
          const SizedBox(height: 12),
          _UptimeCard(uptimeText: data?.uptimeText),
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
    if (raw.isEmpty) return '存储空间${index + 1}';

    final match = RegExp(r'^volume\s*(\d+)$', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      return '存储空间${match.group(1)}';
    }

    if (raw.toLowerCase().startsWith('volume')) {
      return '存储空间${index + 1}';
    }

    return raw;
  }

  String _buildUsageDetail() {
    final used = volume.usedBytes;
    final total = volume.totalBytes;

    if (used != null && used > 0 && total != null && total > 0) {
      return '已用 ${_formatBytes(used)} / 总计 ${_formatBytes(total)}';
    }

    if (used != null && used > 0) {
      return '已用 ${_formatBytes(used)} / 总计 --';
    }

    if (total != null && total > 0) {
      return '已用 -- / 总计 ${_formatBytes(total)}';
    }

    return '已用 -- / 总计 --';
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

  String _formatDuration(Duration duration) {
    final totalHours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    final hh = totalHours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = '暂未获取到运行时间';

    if (_baseDuration != null && _baseTime != null) {
      final current = _baseDuration! + DateTime.now().difference(_baseTime!);
      subtitle = _formatDuration(current);
    } else if (widget.uptimeText != null && widget.uptimeText!.trim().isNotEmpty) {
      subtitle = widget.uptimeText!.trim();
    }

    return SummaryCard(
      title: '运行时间',
      subtitle: subtitle,
      trailing: const Icon(Icons.schedule_outlined),
    );
  }
}
