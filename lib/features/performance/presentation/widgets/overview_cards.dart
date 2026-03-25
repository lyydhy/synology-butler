import 'package:flutter/material.dart';

import 'chart_painters.dart';
import 'metric_cards.dart';

// ─────────────────────────────────────────────────────────────────
//  Overview metric card
// ─────────────────────────────────────────────────────────────────

class OverviewMetricCard extends StatelessWidget {
  const OverviewMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trendValues,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.08), theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
                const Spacer(),
                Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: MiniLineChart(values: trendValues, color: color, height: 72, fill: true),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Dual metric card (network / disk summary)
// ─────────────────────────────────────────────────────────────────

class OverviewDualMetricCard extends StatelessWidget {
  const OverviewDualMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryLabel,
    required this.primaryValue,
    required this.primaryColor,
    required this.primaryTrendValues,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.secondaryColor,
    required this.secondaryTrendValues,
  });

  final String title;
  final IconData icon;
  final String primaryLabel;
  final String primaryValue;
  final Color primaryColor;
  final List<double> primaryTrendValues;
  final String secondaryLabel;
  final String secondaryValue;
  final Color secondaryColor;
  final List<double> secondaryTrendValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), child: Icon(icon, color: theme.colorScheme.primary)),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _DualMetricItem(label: primaryLabel, value: primaryValue, color: primaryColor, trendValues: primaryTrendValues)),
              const SizedBox(width: 12),
              Expanded(child: _DualMetricItem(label: secondaryLabel, value: secondaryValue, color: secondaryColor, trendValues: secondaryTrendValues)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualMetricItem extends StatelessWidget {
  const _DualMetricItem({required this.label, required this.value, required this.color, required this.trendValues});

  final String label;
  final String value;
  final Color color;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(height: 52, child: MiniLineChart(values: trendValues, color: color, height: 52)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Network interface card
// ─────────────────────────────────────────────────────────────────

class NetworkInterfaceCard extends StatelessWidget {
  const NetworkInterfaceCard({
    super.key,
    required this.title,
    required this.uploadValue,
    required this.downloadValue,
    required this.uploadHistory,
    required this.downloadHistory,
  });

  final String title;
  final double uploadValue;
  final double downloadValue;
  final List<double> uploadHistory;
  final List<double> downloadHistory;

  @override
  Widget build(BuildContext context) {
    final showChart = uploadHistory.isNotEmpty || downloadHistory.isNotEmpty;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (showChart) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 116,
              child: MultiLineChart(
                lines: [
                  ChartLine(values: uploadHistory, color: Colors.blue),
                  ChartLine(values: downloadHistory, color: Colors.green),
                ],
                height: 116,
                percentMode: false,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ValueBadgeCard(label: '上传', value: PerfFormatters.bytesPerSecond(uploadValue), color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: ValueBadgeCard(label: '下载', value: PerfFormatters.bytesPerSecond(downloadValue), color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
