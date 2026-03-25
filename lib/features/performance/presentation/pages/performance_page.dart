import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/system_status.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

class PerformancePage extends ConsumerStatefulWidget {
  const PerformancePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends ConsumerState<PerformancePage> with SingleTickerProviderStateMixin {
  static const int _historyLimit = 30;

  late final TabController _tabController;
  ProviderSubscription<AsyncValue<SystemStatus?>>? _overviewSubscription;

  final List<double> _cpuHistory = <double>[];
  final List<double> _cpuUserHistory = <double>[];
  final List<double> _cpuSystemHistory = <double>[];
  final List<double> _cpuIoHistory = <double>[];
  final List<double> _memoryHistory = <double>[];
  final List<double> _storageHistory = <double>[];
  final List<double> _networkUploadHistory = <double>[];
  final List<double> _networkDownloadHistory = <double>[];
  final List<double> _diskReadHistory = <double>[];
  final List<double> _diskWriteHistory = <double>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTab.clamp(0, 5));
    _overviewSubscription = ref.listenManual<AsyncValue<SystemStatus?>>(
      dashboardOverviewSafeProvider,
      (_, next) {
        final data = next.valueOrNull;
        if (data == null) return;
        _push(_cpuHistory, data.cpuUsage);
        _push(_cpuUserHistory, data.cpuUserUsage);
        _push(_cpuSystemHistory, data.cpuSystemUsage);
        _push(_cpuIoHistory, data.cpuIoWaitUsage);
        _push(_memoryHistory, data.memoryUsage);
        _push(_storageHistory, data.storageUsage);
        _push(_networkUploadHistory, data.networkUploadBytesPerSecond);
        _push(_networkDownloadHistory, data.networkDownloadBytesPerSecond);
        _push(_diskReadHistory, data.diskReadBytesPerSecond);
        _push(_diskWriteHistory, data.diskWriteBytesPerSecond);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _overviewSubscription?.close();
    _tabController.dispose();
    super.dispose();
  }

  void _push(List<double> target, double value) {
    if (!mounted) return;
    setState(() {
      target.add(value);
      if (target.length > _historyLimit) {
        target.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(currentSessionProvider);
    final overview = ref.watch(dashboardOverviewSafeProvider);
    final data = overview.valueOrNull;

    if (currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('性能监控')),
        body: const _EmptyState(message: '当前没有可用会话，请先登录'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('性能监控'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: '概览'),
            Tab(text: 'CPU'),
            Tab(text: '内存'),
            Tab(text: '网络'),
            Tab(text: '磁盘'),
            Tab(text: '存储空间'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            data: data,
            cpuHistory: _cpuHistory,
            memoryHistory: _memoryHistory,
            networkUploadHistory: _networkUploadHistory,
            networkDownloadHistory: _networkDownloadHistory,
            diskReadHistory: _diskReadHistory,
            diskWriteHistory: _diskWriteHistory,
            storageHistory: _storageHistory,
          ),
          _CpuTab(
            data: data,
            totalHistory: _cpuHistory,
            userHistory: _cpuUserHistory,
            systemHistory: _cpuSystemHistory,
            ioHistory: _cpuIoHistory,
          ),
          _MemoryTab(
            data: data,
            memoryHistory: _memoryHistory,
          ),
          _NetworkTab(
            data: data,
            uploadHistory: _networkUploadHistory,
            downloadHistory: _networkDownloadHistory,
          ),
          _DiskTab(
            data: data,
            readHistory: _diskReadHistory,
            writeHistory: _diskWriteHistory,
          ),
          _VolumeTab(
            data: data,
            storageHistory: _storageHistory,
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
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
        const _TabSectionHeader(
          title: '概览',
          subtitle: '快速查看当前资源状态与短期趋势',
        ),
        const SizedBox(height: 16),
        _OverviewMetricCard(
          title: 'CPU',
          value: data == null ? '--' : '${data!.cpuUsage.toStringAsFixed(0)}%',
          icon: Icons.memory_outlined,
          color: Colors.blue,
          trendValues: cpuHistory,
        ),
        const SizedBox(height: 16),
        _OverviewMetricCard(
          title: '内存',
          value: data == null ? '--' : '${data!.memoryUsage.toStringAsFixed(0)}%',
          icon: Icons.developer_board_outlined,
          color: Colors.green,
          trendValues: memoryHistory,
        ),
        const SizedBox(height: 16),
        _OverviewDualMetricCard(
          title: '网络',
          icon: Icons.swap_vert_rounded,
          primaryLabel: '上传',
          primaryValue: _Formatters.bytesPerSecond(data?.networkUploadBytesPerSecond),
          primaryColor: Colors.blue,
          primaryTrendValues: networkUploadHistory,
          secondaryLabel: '下载',
          secondaryValue: _Formatters.bytesPerSecond(data?.networkDownloadBytesPerSecond),
          secondaryColor: Colors.green,
          secondaryTrendValues: networkDownloadHistory,
        ),
        const SizedBox(height: 16),
        _OverviewDualMetricCard(
          title: '磁盘',
          icon: Icons.album_outlined,
          primaryLabel: '读取',
          primaryValue: _Formatters.bytesPerSecond(data?.diskReadBytesPerSecond),
          primaryColor: Colors.orange,
          primaryTrendValues: diskReadHistory,
          secondaryLabel: '写入',
          secondaryValue: _Formatters.bytesPerSecond(data?.diskWriteBytesPerSecond),
          secondaryColor: Colors.pink,
          secondaryTrendValues: diskWriteHistory,
        ),
        const SizedBox(height: 16),
        _OverviewMetricCard(
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

class _CpuTab extends StatelessWidget {
  const _CpuTab({
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
        const _TabSectionHeader(
          title: 'CPU',
          subtitle: '查看总利用率、用户态、系统态与 I/O 等待',
        ),
        const SizedBox(height: 16),
        _CpuUsageCard(
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
              child: _ValueBadgeCard(
                label: '用户',
                value: data == null ? '--' : '${data!.cpuUserUsage.toStringAsFixed(0)} %',
                color: const Color(0xFFBAE050),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ValueBadgeCard(
                label: '系统',
                value: data == null ? '--' : '${data!.cpuSystemUsage.toStringAsFixed(0)} %',
                color: const Color(0xFF73B0EE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ValueBadgeCard(
                label: 'I/O',
                value: data == null ? '--' : '${data!.cpuIoWaitUsage.toStringAsFixed(0)} %',
                color: const Color(0xFF5584C8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LoadAverageCard(data: data),
      ],
    );
  }
}

class _MemoryTab extends StatelessWidget {
  const _MemoryTab({
    required this.data,
    required this.memoryHistory,
  });

  final SystemStatus? data;
  final List<double> memoryHistory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TabSectionHeader(
          title: '内存',
          subtitle: '查看内存利用率与当前内存构成',
        ),
        const SizedBox(height: 16),
        _OverviewMetricCard(
          title: '内存利用率',
          value: data == null ? '--' : '${data!.memoryUsage.toStringAsFixed(0)}%',
          icon: Icons.developer_board_outlined,
          color: Colors.green,
          trendValues: memoryHistory,
        ),
        const SizedBox(height: 16),
        _MemorySummaryCard(data: data),
      ],
    );
  }
}

class _NetworkTab extends StatelessWidget {
  const _NetworkTab({
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
      return const _TabScaffoldEmpty(
        title: '网络',
        subtitle: '暂未获取到网卡数据',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TabSectionHeader(
          title: '网络',
          subtitle: '查看总计和各网卡当前上传、下载情况',
        ),
        const SizedBox(height: 16),
        ...interfaces.asMap().entries.map((entry) {
          final item = entry.value;
          final isTotal = entry.key == 0;
          return Padding(
            padding: EdgeInsets.only(bottom: entry.key == interfaces.length - 1 ? 0 : 16),
            child: _NetworkInterfaceCard(
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

class _DiskTab extends StatelessWidget {
  const _DiskTab({
    required this.data,
    required this.readHistory,
    required this.writeHistory,
  });

  final SystemStatus? data;
  final List<double> readHistory;
  final List<double> writeHistory;

  @override
  Widget build(BuildContext context) {
    final disks = data?.disks ?? const <DiskStatus>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TabSectionHeader(
          title: '磁盘',
          subtitle: '查看总读写趋势和每块磁盘的实时状态',
        ),
        const SizedBox(height: 16),
        _OverviewDualMetricCard(
          title: '磁盘读写',
          icon: Icons.album_outlined,
          primaryLabel: '读取',
          primaryValue: _Formatters.bytesPerSecond(data?.diskReadBytesPerSecond),
          primaryColor: Colors.orange,
          primaryTrendValues: readHistory,
          secondaryLabel: '写入',
          secondaryValue: _Formatters.bytesPerSecond(data?.diskWriteBytesPerSecond),
          secondaryColor: Colors.pink,
          secondaryTrendValues: writeHistory,
        ),
        const SizedBox(height: 16),
        if (disks.isEmpty)
          const _EmptyState(message: '暂未获取到磁盘信息')
        else
          ...disks.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == disks.length - 1 ? 0 : 16),
                child: _DiskStatusCard(disk: entry.value),
              )),
      ],
    );
  }
}

class _VolumeTab extends StatelessWidget {
  const _VolumeTab({
    required this.data,
    required this.storageHistory,
  });

  final SystemStatus? data;
  final List<double> storageHistory;

  @override
  Widget build(BuildContext context) {
    final volumes = data?.volumePerformances ?? const <VolumePerformanceStatus>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _TabSectionHeader(
          title: '存储空间',
          subtitle: '查看卷级利用率以及读写、IOPS 情况',
        ),
        const SizedBox(height: 16),
        _OverviewMetricCard(
          title: '存储空间利用率',
          value: data == null ? '--' : '${data!.storageUsage.toStringAsFixed(0)}%',
          icon: Icons.storage_rounded,
          color: Colors.purple,
          trendValues: storageHistory,
        ),
        const SizedBox(height: 16),
        if (volumes.isEmpty)
          const _EmptyState(message: '暂未获取到存储空间信息')
        else
          ...volumes.asMap().entries.map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == volumes.length - 1 ? 0 : 16),
                child: _VolumeStatusCard(volume: entry.value),
              )),
      ],
    );
  }
}

class _TabScaffoldEmpty extends StatelessWidget {
  const _TabScaffoldEmpty({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TabSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 24),
        const _EmptyState(message: '暂无可展示数据'),
      ],
    );
  }
}

class _TabSectionHeader extends StatelessWidget {
  const _TabSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

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
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

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

class _ResourceStatusCard extends StatelessWidget {
  const _ResourceStatusCard({
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
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${utilization.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
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
      if (i != children.length - 1) {
        result.add(const SizedBox(width: 12));
      }
    }
    return result;
  }
}

class _VolumeStatusCard extends StatelessWidget {
  const _VolumeStatusCard({required this.volume});

  final VolumePerformanceStatus volume;

  @override
  Widget build(BuildContext context) {
    return _ResourceStatusCard(
      title: volume.name,
      utilization: volume.utilization,
      topMetrics: [
        _ValueBadgeCard(label: '读取', value: _Formatters.bytesPerSecond(volume.readBytesPerSecond), color: Colors.orange),
        _ValueBadgeCard(label: '写入', value: _Formatters.bytesPerSecond(volume.writeBytesPerSecond), color: Colors.pink),
      ],
      bottomMetrics: [
        _ValueBadgeCard(label: '读 IOPS', value: volume.readIops.toStringAsFixed(0), color: Colors.indigo),
        _ValueBadgeCard(label: '写 IOPS', value: volume.writeIops.toStringAsFixed(0), color: Colors.deepPurple),
      ],
    );
  }
}

class _DiskStatusCard extends StatelessWidget {
  const _DiskStatusCard({required this.disk});

  final DiskStatus disk;

  @override
  Widget build(BuildContext context) {
    return _ResourceStatusCard(
      title: disk.name,
      utilization: disk.utilization,
      topMetrics: [
        _ValueBadgeCard(label: '读取', value: _Formatters.bytesPerSecond(disk.readBytesPerSecond), color: Colors.orange),
        _ValueBadgeCard(label: '写入', value: _Formatters.bytesPerSecond(disk.writeBytesPerSecond), color: Colors.pink),
      ],
      bottomMetrics: [
        _ValueBadgeCard(label: '读 IOPS', value: disk.readIops.toStringAsFixed(0), color: Colors.indigo),
        _ValueBadgeCard(label: '写 IOPS', value: disk.writeIops.toStringAsFixed(0), color: Colors.deepPurple),
      ],
    );
  }
}

class _NetworkInterfaceCard extends StatelessWidget {
  const _NetworkInterfaceCard({
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
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (showChart) ...[
            const SizedBox(height: 14),
            _MultiLineChart(
              lines: [
                _ChartLine(values: uploadHistory, color: Colors.blue),
                _ChartLine(values: downloadHistory, color: Colors.green),
              ],
              height: 116,
              percentMode: false,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ValueBadgeCard(
                  label: '上传',
                  value: _Formatters.bytesPerSecond(uploadValue),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBadgeCard(
                  label: '下载',
                  value: _Formatters.bytesPerSecond(downloadValue),
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemorySummaryCard extends StatelessWidget {
  const _MemorySummaryCard({required this.data});

  final SystemStatus? data;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '内存摘要',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                data == null ? '--' : _Formatters.bytes(data!.memoryTotalBytes),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ValueBadgeCard(
                  label: '已用',
                  value: data == null ? '--' : _Formatters.bytes(data!.memoryUsedBytes),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBadgeCard(
                  label: '缓冲',
                  value: data == null ? '--' : _Formatters.bytes(data!.memoryBufferBytes),
                  color: Colors.lightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ValueBadgeCard(
                  label: '缓存',
                  value: data == null ? '--' : _Formatters.bytes(data!.memoryCachedBytes),
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueBadgeCard(
                  label: '可用',
                  value: data == null ? '--' : _Formatters.bytes(data!.memoryAvailableBytes),
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CpuUsageCard extends StatelessWidget {
  const _CpuUsageCard({
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
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CPU 利用率',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                data == null ? '--' : '${data!.cpuUsage.toStringAsFixed(0)}%',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MiniLineChart(values: totalHistory, color: Colors.blue, height: 116, fill: true),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LegendDot(label: '总利用率', color: Colors.blue),
              _LegendDot(label: '用户', color: Color(0xFFBAE050)),
              _LegendDot(label: '系统', color: Color(0xFF73B0EE)),
              _LegendDot(label: 'I/O', color: Color(0xFF5584C8)),
            ],
          ),
          const SizedBox(height: 14),
          _MultiLineChart(
            lines: [
              _ChartLine(values: totalHistory, color: Colors.blue),
              _ChartLine(values: userHistory, color: const Color(0xFFBAE050)),
              _ChartLine(values: systemHistory, color: const Color(0xFF73B0EE)),
              _ChartLine(values: ioHistory, color: const Color(0xFF5584C8)),
            ],
            height: 132,
          ),
        ],
      ),
    );
  }
}

class _ValueBadgeCard extends StatelessWidget {
  const _ValueBadgeCard({
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

class _LoadAverageCard extends StatelessWidget {
  const _LoadAverageCard({required this.data});

  final SystemStatus? data;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '负载平均',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _LoadItem(label: '1 分钟', value: data == null ? '--' : data!.load1.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: _LoadItem(label: '5 分钟', value: data == null ? '--' : data!.load5.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: _LoadItem(label: '15 分钟', value: data == null ? '--' : data!.load15.toStringAsFixed(2))),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadItem extends StatelessWidget {
  const _LoadItem({required this.label, required this.value});

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
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _ChartLine {
  const _ChartLine({required this.values, required this.color});

  final List<double> values;
  final Color color;
}

class _MultiLineChart extends StatelessWidget {
  const _MultiLineChart({required this.lines, required this.height, this.percentMode = true});

  final List<_ChartLine> lines;
  final double height;
  final bool percentMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MultiLineChartPainter(lines: lines, percentMode: percentMode),
      ),
    );
  }
}

class _MultiLineChartPainter extends CustomPainter {
  const _MultiLineChartPainter({required this.lines, required this.percentMode});

  final List<_ChartLine> lines;
  final bool percentMode;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final allValues = lines.expand((line) => line.values.isEmpty ? const <double>[0] : line.values).toList();
    final maxValue = allValues.isEmpty ? 1.0 : allValues.reduce(math.max);
    final safeMaxValue = percentMode ? 100.0 : (maxValue <= 0 ? 1.0 : maxValue);

    for (final line in lines) {
      final source = line.values.isEmpty ? const <double>[0] : line.values;
      final path = Path();
      for (var i = 0; i < source.length; i++) {
        final x = source.length == 1 ? size.width : size.width * i / (source.length - 1);
        final normalized = percentMode ? source[i].clamp(0, 100) / safeMaxValue : source[i] / safeMaxValue;
        final y = size.height - (normalized * (size.height - 8)) - 4;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineChartPainter oldDelegate) => true;
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
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
            colors: [
              color.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _MiniLineChart(
              values: trendValues,
              color: color,
              height: 72,
              fill: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewDualMetricCard extends StatelessWidget {
  const _OverviewDualMetricCard({
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
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DualMetricItem(
                  label: primaryLabel,
                  value: primaryValue,
                  color: primaryColor,
                  trendValues: primaryTrendValues,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DualMetricItem(
                  label: secondaryLabel,
                  value: secondaryValue,
                  color: secondaryColor,
                  trendValues: secondaryTrendValues,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualMetricItem extends StatelessWidget {
  const _DualMetricItem({
    required this.label,
    required this.value,
    required this.color,
    required this.trendValues,
  });

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
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _MiniLineChart(values: trendValues, color: color, height: 52),
        ],
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({
    required this.values,
    required this.color,
    required this.height,
    this.fill = false,
  });

  final List<double> values;
  final Color color;
  final double height;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MiniLineChartPainter(values: values, color: color, fill: fill),
      ),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  const _MiniLineChartPainter({
    required this.values,
    required this.color,
    required this.fill,
  });

  final List<double> values;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..color = color.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill,
    );

    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final source = values.isEmpty ? const <double>[0] : values;
    final minValue = source.reduce(math.min);
    final maxValue = source.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.001 ? 1.0 : (maxValue - minValue);

    final path = Path();
    for (var i = 0; i < source.length; i++) {
      final x = source.length == 1 ? size.width : size.width * i / (source.length - 1);
      final y = size.height - ((source[i] - minValue) / range * (size.height - 10)) - 5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color || oldDelegate.fill != fill;
  }
}

class _Formatters {
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
