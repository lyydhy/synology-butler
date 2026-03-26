import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../state/performance_history.dart';
import '../widgets/tab_content.dart';

/// 性能监控页。
///
/// 页面只依赖全局连接状态和概览数据流；
/// 历史曲线缓存改回 Flutter 原生 State 管理，避免为局部状态额外引入 Riverpod。
class PerformancePage extends ConsumerStatefulWidget {
  const PerformancePage({super.key, this.initialTab = 0});

  /// 初始选中的页签下标。
  final int initialTab;

  @override
  ConsumerState<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends ConsumerState<PerformancePage> with SingleTickerProviderStateMixin {
  static const int _tabCount = 6;

  late final TabController _tabController;

  /// 当前页面维护的性能历史缓存。
  final PerfHistoryState _history = PerfHistoryState();

  /// 用于避免同一帧数据在 rebuild 时被重复写入历史。
  SystemStatus? _lastRecordedOverview;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabCount - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 在拿到新概览数据时写入历史缓存。
  void _recordOverview(SystemStatus? data) {
    if (data == null || identical(_lastRecordedOverview, data)) {
      return;
    }
    _history.push(data);
    _lastRecordedOverview = data;
  }

  /// 清空页面内的历史曲线。
  void _clearHistory() {
    setState(() {
      _history.clear();
      _lastRecordedOverview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(activeSessionProvider);
    final overview = ref.watch(dashboardOverviewSafeProvider);
    final currentOverview = overview.valueOrNull;

    _recordOverview(currentOverview);

    if (currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('性能监控')),
        body: const Center(child: Text('当前没有可用会话，请先登录')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('性能监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '清除历史并刷新',
            onPressed: _clearHistory,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              tabs: const [
                SlidingTabItem(icon: Icons.dashboard_outlined, label: '概览'),
                SlidingTabItem(icon: Icons.memory_outlined, label: 'CPU'),
                SlidingTabItem(icon: Icons.developer_board_outlined, label: '内存'),
                SlidingTabItem(icon: Icons.swap_vert_rounded, label: '网络'),
                SlidingTabItem(icon: Icons.album_outlined, label: '磁盘'),
                SlidingTabItem(icon: Icons.storage_rounded, label: '存储'),
              ],
            ),
          ),
        ),
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            OverviewTab(
              data: currentOverview,
              cpuHistory: _history.cpu.values,
              memoryHistory: _history.memory.values,
              networkUploadHistory: _history.networkUpload.values,
              networkDownloadHistory: _history.networkDownload.values,
              diskReadHistory: _history.diskRead.values,
              diskWriteHistory: _history.diskWrite.values,
              storageHistory: _history.storage.values,
            ),
            CpuTab(
              data: currentOverview,
              totalHistory: _history.cpu.values,
              userHistory: _history.cpuUser.values,
              systemHistory: _history.cpuSystem.values,
              ioHistory: _history.cpuIo.values,
            ),
            MemoryTab(data: currentOverview, memoryHistory: _history.memory.values),
            NetworkTab(
              data: currentOverview,
              uploadHistory: _history.networkUpload.values,
              downloadHistory: _history.networkDownload.values,
            ),
            DiskTab(
              data: currentOverview,
              readHistory: _history.diskRead.values,
              writeHistory: _history.diskWrite.values,
            ),
            VolumeTab(data: currentOverview, storageHistory: _history.storage.values),
          ],
        ),
      ),
    );
  }
}
