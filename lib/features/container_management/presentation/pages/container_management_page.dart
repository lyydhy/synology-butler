import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('第一版骨架已就绪，后续接入真实数据刷新')));
            },
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SlidingTabBar(
              tabController: _tabController,
              tabs: const [
                SlidingTabItem(icon: Icons.view_list_rounded, label: '容器'),
                SlidingTabItem(icon: Icons.account_tree_outlined, label: 'Compose'),
                SlidingTabItem(icon: Icons.layers_outlined, label: '镜像'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContainerListTab(isUnavailable: isDpanel),
                _ComposeListTab(isUnavailable: isDpanel),
                _ImageListTab(isUnavailable: isDpanel),
              ],
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
  const _ContainerListTab({required this.isUnavailable});

  final bool isUnavailable;

  @override
  State<_ContainerListTab> createState() => _ContainerListTabState();
}

class _ContainerListTabState extends State<_ContainerListTab> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final items = _mockContainers.where((item) {
      if (_selectedFilter == 'running') return item.status == '运行中';
      if (_selectedFilter == 'stopped') return item.status == '已停止';
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemBuilder: (context, index) => _ContainerCard(item: items[index]),
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
  const _ImageListTab({required this.isUnavailable});

  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    if (isUnavailable) return const _UnavailablePlaceholder();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemBuilder: (context, index) => _ImageCard(item: _mockImages[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _mockImages.length,
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({required this.item});

  final _ContainerUiItem item;

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
              _StatusChip(label: item.status, running: isRunning),
            ],
          ),
          const SizedBox(height: 12),
          Text('端口：${item.ports}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () {},
              icon: Icon(isRunning ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded),
              label: Text(isRunning ? '停止' : '启动'),
            ),
          ),
        ],
      ),
    );
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

  final _ImageUiItem item;

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
          Text(item.size, style: theme.textTheme.bodyMedium),
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

class _ContainerUiItem {
  const _ContainerUiItem({
    required this.name,
    required this.image,
    required this.status,
    required this.ports,
  });

  final String name;
  final String image;
  final String status;
  final String ports;
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

class _ImageUiItem {
  const _ImageUiItem({
    required this.name,
    required this.tag,
    required this.size,
  });

  final String name;
  final String tag;
  final String size;
}

const _mockContainers = [
  _ContainerUiItem(name: 'nginx-proxy', image: 'nginx:1.27', status: '运行中', ports: '8080 → 80'),
  _ContainerUiItem(name: 'qbittorrent', image: 'lscr.io/linuxserver/qbittorrent', status: '已停止', ports: '8081 → 8080'),
  _ContainerUiItem(name: 'homeassistant', image: 'ghcr.io/home-assistant/home-assistant', status: '运行中', ports: '8123 → 8123'),
];

const _mockComposeProjects = [
  _ComposeUiItem(name: 'media-stack', status: '运行中', containerCount: 4),
  _ComposeUiItem(name: 'download-stack', status: '已停止', containerCount: 2),
];

const _mockImages = [
  _ImageUiItem(name: 'nginx', tag: '1.27', size: '188 MB'),
  _ImageUiItem(name: 'postgres', tag: '16', size: '412 MB'),
  _ImageUiItem(name: 'redis', tag: '7', size: '93 MB'),
];
