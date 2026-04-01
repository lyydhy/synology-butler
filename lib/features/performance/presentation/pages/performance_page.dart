import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final connection = ref.watch(currentConnectionProvider);
    final currentSession = connection.session;
    final overview = ref.watch(dashboardOverviewSafeProvider);
    final currentOverview = overview.valueOrNull;

    _recordOverview(currentOverview);

    if (currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.performanceMonitor)),
        body: Center(child: Text(l10n.noSessionPleaseLogin)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.performanceMonitor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.clearHistoryAndRefresh,
            onPressed: _clearHistory,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              height: 54,
              iconSize: 18,
              fontSize: 13,
              tabs: [
                SlidingTabItem(icon: Icons.dashboard_outlined, label: l10n.overview),
                SlidingTabItem(icon: Icons.memory_outlined, label: l10n.cpu),
                SlidingTabItem(icon: Icons.developer_board_outlined, label: l10n.memory),
                SlidingTabItem(icon: Icons.swap_vert_rounded, label: l10n.network),
                SlidingTabItem(icon: Icons.album_outlined, label: l10n.disk),
                SlidingTabItem(icon: Icons.storage_rounded, label: l10n.storage),
              ],
            ),
          ),
        ),
      ),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.loadFailed(e.toString()))),
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
