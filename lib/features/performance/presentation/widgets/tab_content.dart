import 'package:flutter/material.dart';

import '../../../../domain/entities/system_status.dart';
import 'metric_cards.dart';
import 'overview_cards.dart';

class TabSectionHeader extends StatelessWidget {
  const TabSectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
      ],
    );
  }
}

class PerfEmptyState extends StatelessWidget {
  const PerfEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 28, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.data,
    required this.cpuHistory,
    required this.memoryHistory,
    required this.networkUploadHistory,
    required this.networkDownloadHistory,
    required this.diskReadHistory,
    required this.diskWriteHistory,
    required this.storageHistory,
  });

  final SystemStatus? data;
  final List<double> cpuHistory;
  final List<double> memoryHistory;
  final List<double> networkUploadHistory;
  final List<double> networkDownloadHistory;
  final List<double> diskReadHistory;
  final List<double> diskWriteHistory;
  final List<double> storageHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TabSectionHeader(title: '概览', subtitle: '快速查看当前资源状态与短期趋势'),
        const SizedBox(height: 16),
        OverviewMetricCard(
          title: 'CPU',
          value: data == null ? '--' : '${data!.cpuUsage.toStringAsFixed(0)}%',
          icon: Icons.memory_outlined,
          color: Colors.blue,
          trendValues: cpuHistory,
        ),
        const SizedBox(height: 16),
        OverviewMetricCard(
          title: '内存',
          value: data == null ? '--' : '${data!.memoryUsage.toStringAsFixed(0)}%',
          icon: Icons.developer_board_outlined,
          color: Colors.green,
          trendValues: memoryHistory,
        ),
        const SizedBox(height: 16),
        OverviewDualMetricCard(
          title: '网络',
          icon: Icons.swap_vert_rounded,
          primaryLabel: '上传',
          primaryValue: PerfFormatters.bytesPerSecond(data?.networkUploadBytesPerSecond),
          primaryColor: Colors.blue,
          primaryTrendValues: networkUploadHistory,
          secondaryLabel: '下载',
          secondaryValue: PerfFormatters.bytesPerSecond(data?.networkDownloadBytesPerSecond),
          secondaryColor: Colors.green,
          secondaryTrendValues: networkDownloadHistory,
        ),
        const SizedBox(height: 16),
        OverviewDualMetricCard(
          title: '磁盘',
          icon: Icons.album_outlined,
          primaryLabel: '读取',
          primaryValue: PerfFormatters.bytesPerSecond(data?.diskReadBytesPerSecond),
          primaryColor: Colors.orange,
          primaryTrendValues: diskReadHistory,
          secondaryLabel: '写入',
          secondaryValue: PerfFormatters.bytesPerSecond(data?.diskWriteBytesPerSecond),
          secondaryColor: Colors.pink,
          secondaryTrendValues: diskWriteHistory,
        ),
        const SizedBox(height: 16),
        OverviewMetricCard(
          title: '存储空间',
          value: data == null ? '--' : '${data!.storageUsage.toStringAsFixed(0)}%',
          icon: Icons.storage_rounded,
          color: Colors.purple,
          trendValues: storageHistory,
        ),
      ],
    );
  }
}

class CpuTab extends StatelessWidget {
  const CpuTab({
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TabSectionHeader(title: 'CPU', subtitle: '查看总利用率、用户态、系统态与 I/O 等待'),
        const SizedBox(height: 16),
        CpuUsageCard(
          data: data,
          totalHistory: totalHistory,
          userHistory: userHistory,
          systemHistory: systemHistory,
          ioHistory: ioHistory,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ValueBadgeCard(
                  label: '用户',
                  value: data == null ? '--' : '${data!.cpuUserUsage.toStringAsFixed(0)} %',
                  color: const Color(0xFFBAE050))),
            const SizedBox(width: 12),
            Expanded(
              child: ValueBadgeCard(
                  label: '系统',
                  value: data == null ? '--' : '${data!.cpuSystemUsage.toStringAsFixed(0)} %',
                  color: const Color(0xFF73B0EE))),
            const SizedBox(width: 12),
            Expanded(
              child: ValueBadgeCard(
                  label: 'I/O',
                  value: data == null ? '--' : '${data!.cpuIoWaitUsage.toStringAsFixed(0)} %',
                  color: const Color(0xFF5584C8))),
          ],
        ),
        const SizedBox(height: 16),
        LoadAverageCard(data: data),
      ],
    );
  }
}

class MemoryTab extends StatelessWidget {
  const MemoryTab({super.key, required this.data, required this.memoryHistory});

  final SystemStatus? data;
  final List<double> memoryHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TabSectionHeader(title: '内存', subtitle: '查看内存利用率与当前内存构成'),
        const SizedBox(height: 16),
        OverviewMetricCard(
          title: '内存利用率',
          value: data == null ? '--' : '${data!.memoryUsage.toStringAsFixed(0)}%',
          icon: Icons.developer_board_outlined,
          color: Colors.green,
          trendValues: memoryHistory,
        ),
        const SizedBox(height: 16),
        MemorySummaryCard(data: data),
      ],
    );
  }
}

class NetworkTab extends StatelessWidget {
  const NetworkTab({
    super.key,
    required this.data,
    required this.uploadHistory,
    required this.downloadHistory,
  });

  final SystemStatus? data;
  final List<double> uploadHistory;
  final List<double> downloadHistory;

  @override
  Widget build(BuildContext context) {
    final interfaces = data?.networkInterfaces ?? const <NetworkInterfaceStatus>[];
    if (interfaces.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TabSectionHeader(title: '网络', subtitle: '查看总计和各网卡当前上传、下载情况'),
          SizedBox(height: 24),
          PerfEmptyState(message: '暂未获取到网卡数据'),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TabSectionHeader(title: '网络', subtitle: '查看总计和各网卡当前上传、下载情况'),
        const SizedBox(height: 16),
        ...interfaces.asMap().entries.map((entry) {
          final item = entry.value;
          final isTotal = entry.key == 0;
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key == interfaces.length - 1 ? 0 : 16),
            child: NetworkInterfaceCard(
              title: item.name,
              uploadValue: item.uploadBytesPerSecond,
              downloadValue: item.downloadBytesPerSecond,
              uploadHistory: isTotal ? uploadHistory : const <double>[],
              downloadHistory: isTotal ? downloadHistory : const <double>[],
            ),
          );
        }),
      ],
    );
  }
}

class DiskTab extends StatelessWidget {
  const DiskTab({super.key, required this.data, required this.readHistory, required this.writeHistory});

  final SystemStatus? data;
  final List<double> readHistory;
  final List<double> writeHistory;

  @override
  Widget build(BuildContext context) {
    final disks = data?.disks ?? const <DiskStatus>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TabSectionHeader(title: '磁盘', subtitle: '查看总读写趋势和每块磁盘的实时状态'),
        const SizedBox(height: 16),
        OverviewDualMetricCard(
          title: '磁盘读写',
          icon: Icons.album_outlined,
          primaryLabel: '读取',
          primaryValue: PerfFormatters.bytesPerSecond(data?.diskReadBytesPerSecond),
          primaryColor: Colors.orange,
          primaryTrendValues: readHistory,
          secondaryLabel: '写入',
          secondaryValue: PerfFormatters.bytesPerSecond(data?.diskWriteBytesPerSecond),
          secondaryColor: Colors.pink,
          secondaryTrendValues: writeHistory,
        ),
        const SizedBox(height: 16),
        if (disks.isEmpty)
          const PerfEmptyState(message: '暂未获取到磁盘信息')
        else
          ...disks.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == disks.length - 1 ? 0 : 16),
                child: DiskStatusCard(disk: entry.value),
              )),
      ],
    );
  }
}

class VolumeTab extends StatelessWidget {
  const VolumeTab({super.key, required this.data, required this.storageHistory});

  final SystemStatus? data;
  final List<double> storageHistory;

  @override
  Widget build(BuildContext context) {
    final volumes = data?.volumePerformances ?? const <VolumePerformanceStatus>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const TabSectionHeader(title: '存储空间', subtitle: '查看卷级利用率以及读写、IOPS 情况'),
        const SizedBox(height: 16),
        OverviewMetricCard(
          title: '存储空间利用率',
          value: data == null ? '--' : '${data!.storageUsage.toStringAsFixed(0)}%',
          icon: Icons.storage_rounded,
          color: Colors.purple,
          trendValues: storageHistory,
        ),
        const SizedBox(height: 16),
        if (volumes.isEmpty)
          const PerfEmptyState(message: '暂未获取到存储空间信息')
        else
          ...volumes.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == volumes.length - 1 ? 0 : 16),
                child: VolumeStatusCard(volume: entry.value),
              )),
      ],
    );
  }
}
