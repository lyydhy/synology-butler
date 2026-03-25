import 'package:flutter/material.dart';

import '../../../../domain/entities/system_status.dart';
import 'chart_painters.dart';

// ─────────────────────────────────────────────────────────────────
//  Base surface card
// ─────────────────────────────────────────────────────────────────

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.18)),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Metric value badge
// ─────────────────────────────────────────────────────────────────

class ValueBadgeCard extends StatelessWidget {
  const ValueBadgeCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Load average item
// ─────────────────────────────────────────────────────────────────

class LoadItem extends StatelessWidget {
  const LoadItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Legend dot
// ─────────────────────────────────────────────────────────────────

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Resource status card (disk / volume)
// ─────────────────────────────────────────────────────────────────

class ResourceStatusCard extends StatelessWidget {
  const ResourceStatusCard({
    super.key,
    required this.title,
    required this.utilization,
    required this.topMetrics,
    required this.bottomMetrics,
  });

  final String title;
  final double utilization;
  final List<Widget> topMetrics;
  final List<Widget> bottomMetrics;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Text('${utilization.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (utilization / 100).clamp(0.0, 1.0),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: _withSpacing(topMetrics)),
          const SizedBox(height: 12),
          Row(children: _withSpacing(bottomMetrics)),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(Expanded(child: children[i]));
      if (i != children.length - 1) result.add(const SizedBox(width: 12));
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────
//  Volume status card
// ─────────────────────────────────────────────────────────────────

class VolumeStatusCard extends StatelessWidget {
  const VolumeStatusCard({super.key, required this.volume});

  final VolumePerformanceStatus volume;

  @override
  Widget build(BuildContext context) {
    return ResourceStatusCard(
      title: volume.name,
      utilization: volume.utilization,
      topMetrics: [
        ValueBadgeCard(label: '读取', value: PerfFormatters.bytesPerSecond(volume.readBytesPerSecond), color: Colors.orange),
        ValueBadgeCard(label: '写入', value: PerfFormatters.bytesPerSecond(volume.writeBytesPerSecond), color: Colors.pink),
      ],
      bottomMetrics: [
        ValueBadgeCard(label: '读 IOPS', value: volume.readIops.toStringAsFixed(0), color: Colors.indigo),
        ValueBadgeCard(label: '写 IOPS', value: volume.writeIops.toStringAsFixed(0), color: Colors.deepPurple),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Disk status card
// ─────────────────────────────────────────────────────────────────

class DiskStatusCard extends StatelessWidget {
  const DiskStatusCard({super.key, required this.disk});

  final DiskStatus disk;

  @override
  Widget build(BuildContext context) {
    return ResourceStatusCard(
      title: disk.name,
      utilization: disk.utilization,
      topMetrics: [
        ValueBadgeCard(label: '读取', value: PerfFormatters.bytesPerSecond(disk.readBytesPerSecond), color: Colors.orange),
        ValueBadgeCard(label: '写入', value: PerfFormatters.bytesPerSecond(disk.writeBytesPerSecond), color: Colors.pink),
      ],
      bottomMetrics: [
        ValueBadgeCard(label: '读 IOPS', value: disk.readIops.toStringAsFixed(0), color: Colors.indigo),
        ValueBadgeCard(label: '写 IOPS', value: disk.writeIops.toStringAsFixed(0), color: Colors.deepPurple),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Memory summary card
// ─────────────────────────────────────────────────────────────────

class MemorySummaryCard extends StatelessWidget {
  const MemorySummaryCard({super.key, required this.data});

  final SystemStatus? data;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('内存摘要', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(data == null ? '--' : PerfFormatters.bytes(data!.memoryTotalBytes),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ValueBadgeCard(label: '已用', value: data == null ? '--' : PerfFormatters.bytes(data!.memoryUsedBytes), color: Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: ValueBadgeCard(label: '缓冲', value: data == null ? '--' : PerfFormatters.bytes(data!.memoryBufferBytes), color: Colors.lightBlue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ValueBadgeCard(label: '缓存', value: data == null ? '--' : PerfFormatters.bytes(data!.memoryCachedBytes), color: Colors.cyan)),
              const SizedBox(width: 12),
              Expanded(child: ValueBadgeCard(label: '可用', value: data == null ? '--' : PerfFormatters.bytes(data!.memoryAvailableBytes), color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  CPU usage card
// ─────────────────────────────────────────────────────────────────

class CpuUsageCard extends StatelessWidget {
  const CpuUsageCard({
    super.key,
    required this.data,
    required this.totalHistory,
    required this.userHistory,
    required this.systemHistory,
    required this.ioHistory,
  });

  final SystemStatus? data;
  final List<double> totalHistory;
  final List<double> userHistory;
  final List<double> systemHistory;
  final List<double> ioHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CPU 利用率', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(data == null ? '--' : '${data!.cpuUsage.toStringAsFixed(0)}%',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          MiniLineChart(values: totalHistory, color: Colors.blue, height: 116, fill: true),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              LegendDot(label: '总利用率', color: Colors.blue),
              LegendDot(label: '用户', color: Color(0xFFBAE050)),
              LegendDot(label: '系统', color: Color(0xFF73B0EE)),
              LegendDot(label: 'I/O', color: Color(0xFF5584C8)),
            ],
          ),
          const SizedBox(height: 14),
          MultiLineChart(
            lines: [
              ChartLine(values: totalHistory, color: Colors.blue),
              ChartLine(values: userHistory, color: const Color(0xFFBAE050)),
              ChartLine(values: systemHistory, color: const Color(0xFF73B0EE)),
              ChartLine(values: ioHistory, color: const Color(0xFF5584C8)),
            ],
            height: 132,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Load average card
// ─────────────────────────────────────────────────────────────────

class LoadAverageCard extends StatelessWidget {
  const LoadAverageCard({super.key, required this.data});

  final SystemStatus? data;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('负载平均', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: LoadItem(label: '1 分钟', value: data == null ? '--' : data!.load1.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: LoadItem(label: '5 分钟', value: data == null ? '--' : data!.load5.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: LoadItem(label: '15 分钟', value: data == null ? '--' : data!.load15.toStringAsFixed(2))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Formatters
// ─────────────────────────────────────────────────────────────────

class PerfFormatters {
  static String bytes(double? value) {
    if (value == null || value <= 0) return '--';
    return _format(value, ['B', 'KB', 'MB', 'GB', 'TB', 'PB']);
  }

  static String bytesPerSecond(double? value) {
    if (value == null || value <= 0) return '--';
    return _format(value, ['B/s', 'KB/s', 'MB/s', 'GB/s', 'TB/s']);
  }

  static String _format(double value, List<String> units) {
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }
}
