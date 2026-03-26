import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../data/api/docker_api.dart';
import '../../../preferences/providers/preferences_providers.dart';

/// 容器管理首页。
///
/// 第一版先提供稳定、轻量的页面骨架：
/// - 使用通用滑动 Tab 组件保证视觉统一
/// - 页面筛选等状态尽量留在 StatefulWidget 内部
/// - 数据源切换放到模块自己的设置页，避免污染全局设置
class ContainerManagementPage extends ConsumerStatefulWidget {
  const ContainerManagementPage({super.key});

  @override
  ConsumerState<ContainerManagementPage> createState() => _ContainerManagementPageState();
}

class _ContainerManagementPageState extends ConsumerState<ContainerManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<DockerOverviewData> _overviewFuture;
  final Set<String> _containerActionLoading = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _overviewFuture = DsmDockerApi().fetchOverview();
  }

  /// 统一刷新容器与镜像数据。
  void _refreshOverview() {
    setState(() {
      _overviewFuture = DsmDockerApi().fetchOverview();
    });
  }

  /// 容器启停操作统一入口。
  Future<void> _toggleContainer(DockerContainerSummary item) async {
    final isRunning = item.status == 'running';
    await _runContainerAction(
      item: item,
      successVerb: isRunning ? '停止' : '启动',
      action: (api) => isRunning ? api.stopContainer(name: item.name) : api.startContainer(name: item.name),
    );
  }

  Future<void> _restartContainer(DockerContainerSummary item) async {
    await _runContainerAction(
      item: item,
      successVerb: '重启',
      action: (api) => api.restartContainer(name: item.name),
    );
  }

  Future<void> _forceStopContainer(DockerContainerSummary item) async {
    await _runContainerAction(
      item: item,
      successVerb: '强制停止',
      action: (api) => api.forceStopContainer(name: item.name),
    );
  }

  Future<void> _runContainerAction({
    required DockerContainerSummary item,
    required String successVerb,
    required Future<void> Function(DsmDockerApi api) action,
  }) async {
    setState(() {
      _containerActionLoading.add(item.id);
    });

    try {
      final api = DsmDockerApi();
      await action(api);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$successVerb容器成功：${item.name}')));
      _refreshOverview();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$successVerb容器失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _containerActionLoading.remove(item.id);
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataSource = ref.watch(containerDataSourceProvider);
    final isDpanel = dataSource == ContainerDataSourceOption.dpanel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('容器管理'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _refreshOverview,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push('/container-management/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SourceBanner(source: dataSource),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              height: 54,
              iconSize: 18,
              fontSize: 13,
              tabs: const [
                SlidingTabItem(icon: Icons.view_list_rounded, label: '容器'),
                SlidingTabItem(icon: Icons.account_tree_outlined, label: 'Compose'),
                SlidingTabItem(icon: Icons.layers_outlined, label: '镜像'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<DockerOverviewData>(
              future: _overviewFuture,
              builder: (context, snapshot) {
                if (isDpanel) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _ContainerListTab(
                        isUnavailable: true,
                        items: const [],
                        loadingIds: const <String>{},
                        onToggle: (_) async {},
                        onRestart: (_) async {},
                        onForceStop: (_) async {},
                      ),
                      const _ComposeListTab(isUnavailable: true),
                      const _ImageListTab(isUnavailable: true, items: []),
                    ],
                  );
                }

                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _DockerErrorState(onRetry: _refreshOverview);
                }

                final data = snapshot.data ?? const DockerOverviewData(containers: [], images: []);
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _ContainerListTab(
                      isUnavailable: false,
                      items: data.containers,
                      loadingIds: _containerActionLoading,
                      onToggle: _toggleContainer,
                      onRestart: _restartContainer,
                      onForceStop: _forceStopContainer,
                    ),
                    const _ComposeListTab(isUnavailable: false),
                    _ImageListTab(isUnavailable: false, items: data.images),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

class _SourceBanner extends StatelessWidget {
  const _SourceBanner({required this.source});

  final ContainerDataSourceOption source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSynology = source == ContainerDataSourceOption.synology;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isSynology ? Icons.dns_outlined : Icons.developer_board_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前数据源：${isSynology ? '群晖 DSM / Container Manager' : 'dpanel'}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isSynology ? '第一版默认使用群晖原生容器数据源。' : 'dpanel 适配预留中，当前先展示模块骨架。',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContainerListTab extends StatefulWidget {
  const _ContainerListTab({
    required this.isUnavailable,
    required this.items,
    required this.loadingIds,
    required this.onToggle,
    required this.onRestart,
    required this.onForceStop,
  });

  final bool isUnavailable;
  final List<DockerContainerSummary> items;
  final Set<String> loadingIds;
  final Future<void> Function(DockerContainerSummary item) onToggle;
  final Future<void> Function(DockerContainerSummary item) onRestart;
  final Future<void> Function(DockerContainerSummary item) onForceStop;

  @override
  State<_ContainerListTab> createState() => _ContainerListTabState();
}

class _ContainerListTabState extends State<_ContainerListTab> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final items = widget.items.where((item) {
      if (_selectedFilter == 'running') return item.status == 'running';
      if (_selectedFilter == 'stopped') return item.status == 'stopped';
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('全部')),
              ButtonSegment(value: 'running', label: Text('运行中')),
              ButtonSegment(value: 'stopped', label: Text('已停止')),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (value) => setState(() => _selectedFilter = value.first),
          ),
        ),
        Expanded(
          child: widget.isUnavailable
              ? const _UnavailablePlaceholder()
              : items.isEmpty
                  ? const _EmptyState(label: '暂无容器数据')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemBuilder: (context, index) => _ContainerCard(
                        item: items[index],
                        loading: widget.loadingIds.contains(items[index].id),
                        onToggle: () => widget.onToggle(items[index]),
                        onRestart: () => widget.onRestart(items[index]),
                        onForceStop: () => widget.onForceStop(items[index]),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: items.length,
                    ),
        ),
      ],
    );
  }
}

class _ComposeListTab extends StatelessWidget {
  const _ComposeListTab({required this.isUnavailable});

  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    if (isUnavailable) return const _UnavailablePlaceholder();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemBuilder: (context, index) => _ComposeCard(item: _mockComposeProjects[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _mockComposeProjects.length,
    );
  }
}

class _ImageListTab extends StatelessWidget {
  const _ImageListTab({required this.isUnavailable, required this.items});

  final bool isUnavailable;
  final List<DockerImageSummary> items;

  @override
  Widget build(BuildContext context) {
    if (isUnavailable) return const _UnavailablePlaceholder();

    if (items.isEmpty) return const _EmptyState(label: '暂无镜像数据');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemBuilder: (context, index) => _ImageCard(item: items[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({
    required this.item,
    required this.loading,
    required this.onToggle,
    required this.onRestart,
    required this.onForceStop,
  });

  final DockerContainerSummary item;
  final bool loading;
  final VoidCallback onToggle;
  final VoidCallback onRestart;
  final VoidCallback onForceStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = item.status == 'running';
    final statusText = isRunning ? '运行中' : item.status == 'stopped' ? '已停止' : item.status;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/container-management/detail', extra: {'name': item.name}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(item.image, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _StatusChip(label: statusText, running: isRunning),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: '更多操作',
                onSelected: (value) {
                  switch (value) {
                    case 'restart':
                      onRestart();
                      break;
                    case 'forceStop':
                      onForceStop();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'restart', child: Text('重启')),
                  PopupMenuItem(value: 'forceStop', child: Text('强制停止')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('端口：${item.portsSummary}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: loading ? null : onToggle,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded),
              label: Text(loading ? '处理中' : (isRunning ? '停止' : '启动')),
            ),
          ),
        ],
      ),
    ));
  }
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({required this.item});

  final _ComposeUiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = item.status == '运行中';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_tree_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('容器数：${item.containerCount}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(label: item.status, running: isRunning),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(isRunning ? '停止' : '启动'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.item});

  final DockerImageSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.layers_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tag：${item.tag}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(item.sizeText, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.running});

  final String label;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final color = running ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _UnavailablePlaceholder extends StatelessWidget {
  const _UnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_rounded, size: 42),
            SizedBox(height: 12),
            Text('dpanel 数据源开发中，当前先使用群晖数据源。', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DockerErrorState extends StatelessWidget {
  const _DockerErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42),
            const SizedBox(height: 12),
            const Text('容器数据加载失败，请稍后重试。', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}

class _ComposeUiItem {
  const _ComposeUiItem({
    required this.name,
    required this.status,
    required this.containerCount,
  });

  final String name;
  final String status;
  final int containerCount;
}

const _mockComposeProjects = [
  _ComposeUiItem(name: 'media-stack', status: '运行中', containerCount: 4),
  _ComposeUiItem(name: 'download-stack', status: '已停止', containerCount: 2),
];
