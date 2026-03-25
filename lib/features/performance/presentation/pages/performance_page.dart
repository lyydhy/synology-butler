import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../../domain/entities/system_status.dart';

import '../widgets/tab_content.dart';

// ─────────────────────────────────────────────────────────────────
//  History state
// ─────────────────────────────────────────────────────────────────

class PerfHistory {
  PerfHistory([int limit = 30]) : _limit = limit;

  final int _limit;
  final List<double> _values = [];

  List<double> get values => _values;

  void push(double value) {
    _values.add(value);
    if (_values.length > _limit) _values.removeAt(0);
  }

  void clear() => _values.clear();
}

class PerfHistoryState {
  PerfHistoryState() {
    cpu = PerfHistory();
    cpuUser = PerfHistory();
    cpuSystem = PerfHistory();
    cpuIo = PerfHistory();
    memory = PerfHistory();
    storage = PerfHistory();
    networkUpload = PerfHistory();
    networkDownload = PerfHistory();
    diskRead = PerfHistory();
    diskWrite = PerfHistory();
  }

  late final PerfHistory cpu;
  late final PerfHistory cpuUser;
  late final PerfHistory cpuSystem;
  late final PerfHistory cpuIo;
  late final PerfHistory memory;
  late final PerfHistory storage;
  late final PerfHistory networkUpload;
  late final PerfHistory networkDownload;
  late final PerfHistory diskRead;
  late final PerfHistory diskWrite;

  void clear() {
    cpu.clear();
    cpuUser.clear();
    cpuSystem.clear();
    cpuIo.clear();
    memory.clear();
    storage.clear();
    networkUpload.clear();
    networkDownload.clear();
    diskRead.clear();
    diskWrite.clear();
  }
}

class PerfHistoryNotifier extends StateNotifier<PerfHistoryState> {
  PerfHistoryNotifier() : super(PerfHistoryState());

  void push(SystemStatus data) {
    state.cpu.push(data.cpuUsage);
    state.cpuUser.push(data.cpuUserUsage);
    state.cpuSystem.push(data.cpuSystemUsage);
    state.cpuIo.push(data.cpuIoWaitUsage);
    state.memory.push(data.memoryUsage);
    state.storage.push(data.storageUsage);
    state.networkUpload.push(data.networkUploadBytesPerSecond);
    state.networkDownload.push(data.networkDownloadBytesPerSecond);
    state.diskRead.push(data.diskReadBytesPerSecond);
    state.diskWrite.push(data.diskWriteBytesPerSecond);
  }

  void clear() => state.clear();
}

final perfHistoryProvider = StateNotifierProvider<PerfHistoryNotifier, PerfHistoryState>((ref) {
  return PerfHistoryNotifier();
});

// ─────────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────────

class PerformancePage extends ConsumerStatefulWidget {
  const PerformancePage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends ConsumerState<PerformancePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTab.clamp(0, 5));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(activeSessionProvider);
    final overview = ref.watch(dashboardOverviewSafeProvider);

    // Push data into history whenever the value is available
    overview.whenData((data) {
      if (data != null) {
        ref.read(perfHistoryProvider.notifier).push(data);
      }
    });

    final history = ref.watch(perfHistoryProvider);

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
            onPressed: () => ref.read(perfHistoryProvider.notifier).clear(),
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
              data: overview.valueOrNull,
              cpuHistory: history.cpu.values,
              memoryHistory: history.memory.values,
              networkUploadHistory: history.networkUpload.values,
              networkDownloadHistory: history.networkDownload.values,
              diskReadHistory: history.diskRead.values,
              diskWriteHistory: history.diskWrite.values,
              storageHistory: history.storage.values,
            ),
            CpuTab(
              data: overview.valueOrNull,
              totalHistory: history.cpu.values,
              userHistory: history.cpuUser.values,
              systemHistory: history.cpuSystem.values,
              ioHistory: history.cpuIo.values,
            ),
            MemoryTab(data: overview.valueOrNull, memoryHistory: history.memory.values),
            NetworkTab(
              data: overview.valueOrNull,
              uploadHistory: history.networkUpload.values,
              downloadHistory: history.networkDownload.values,
            ),
            DiskTab(data: overview.valueOrNull, readHistory: history.diskRead.values, writeHistory: history.diskWrite.values),
            VolumeTab(data: overview.valueOrNull, storageHistory: history.storage.values),
          ],
        ),
      ),
    );
  }
}
