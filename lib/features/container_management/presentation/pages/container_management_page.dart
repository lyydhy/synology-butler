import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
      successVerb: isRunning ? l10n.stop : l10n.start,
      action: (api) => isRunning ? api.stopContainer(name: item.name) : api.startContainer(name: item.name),
    );
  }

  Future<void> _restartContainer(DockerContainerSummary item) async {
    await _runContainerAction(
      item: item,
      successVerb: l10n.restart,
      action: (api) => api.restartContainer(name: item.name),
    );
  }

  Future<void> _forceStopContainer(DockerContainerSummary item) async {
    await _runContainerAction(
      item: item,
      successVerb: l10n.forceStop,
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
      Toast.success(l10n.containerSuccess(successVerb, item.name));
      _refreshOverview();
    } catch (error) {
      if (!mounted) return;
      Toast.error(l10n.containerFailed(successVerb, error.toString()));
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
        title: Text(l10n.containerManagement),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _refreshOverview,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l10n.settings,
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
                SlidingTabItem(icon: Icons.view_list_rounded, label: l10n.containerTab),
                SlidingTabItem(icon: Icons.account_tree_outlined, label: l10n.composeTab),
                SlidingTabItem(icon: Icons.layers_outlined, label: l10n.imageTab),
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
                      const _ComposeListTab(isUnavailable: true, containers: [], projects: []),
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

                final data = snapshot.data ?? const DockerOverviewData(containers: [], images: [], projects: []);
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
                    _ComposeListTab(
                      isUnavailable: false,
                      containers: data.containers,
                      projects: data.projects,
                    ),
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
                  l10n.currentDataSource,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isSynology ? l10n.dsmDataSourceDescription : l10n.dpanelDataSourceDescription,
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
            segments: [
              ButtonSegment(value: 'all', label: Text(l10n.containerAll)),
              ButtonSegment(value: 'running', label: Text(l10n.containerRunning)),
              ButtonSegment(value: 'stopped', label: Text(l10n.containerStopped)),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (value) => setState(() => _selectedFilter = value.first),
          ),
        ),
        Expanded(
          child: widget.isUnavailable
              ? const _UnavailablePlaceholder()
              : items.isEmpty
                  ? const _EmptyState(label: l10n.noContainerData)
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

class _ComposeListTab extends StatefulWidget {
  const _ComposeListTab({
    required this.isUnavailable,
    required this.containers,
    required this.projects,
  });

  final bool isUnavailable;
  final List<DockerContainerSummary> containers;
  final List<DockerComposeProjectSummary> projects;

  @override
  State<_ComposeListTab> createState() => _ComposeListTabState();
}

class _ComposeListTabState extends State<_ComposeListTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.isUnavailable) return const _UnavailablePlaceholder();

    final items = _buildComposeProjects(
      projects: widget.projects,
      containers: widget.containers,
      searchQuery: '',
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.projects.isEmpty ? l10n.noDsmComposeProjects : l10n.usingDsmComposeProjects,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final refreshed = await context.push<bool>('/container-management/compose-create');
                  if (refreshed == true && context.mounted) {
                    final pageState = context.findAncestorStateOfType<_ContainerManagementPageState>();
                    pageState?._refreshOverview();
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.create),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const _EmptyState(label: l10n.noComposeProjects)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemBuilder: (context, index) => _ComposeCard(item: items[index]),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: items.length,
                ),
        ),
      ],
    );
  }
}

class _ImageListTab extends StatefulWidget {
  const _ImageListTab({required this.isUnavailable, required this.items});

  final bool isUnavailable;
  final List<DockerImageSummary> items;

  @override
  State<_ImageListTab> createState() => _ImageListTabState();
}

class _ImageListTabState extends State<_ImageListTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.isUnavailable) return const _UnavailablePlaceholder();

    final items = widget.items.toList()..sort((a, b) => a.name.compareTo(b.name));

    return items.isEmpty
        ? const _EmptyState(label: l10n.noImageData)
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
    final statusText = isRunning ? l10n.running : item.status == 'stopped' ? l10n.containerStopped : item.status;

    return AppSurfaceCard(
      onTap: () => context.push('/container-management/detail', extra: {'name': item.name}),
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
              AppStatusChip(
                label: statusText,
                color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: l10n.moreOptions,
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
                  PopupMenuItem(value: 'restart', child: Text(l10n.restart)),
                  PopupMenuItem(value: 'forceStop', child: Text(l10n.forceStop)),
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
              label: Text(loading ? l10n.processingLabel : (isRunning ? l10n.stop : l10n.start)),
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
    final isRunning = item.status == 'running';

    return AppSurfaceCard(
      onTap: () async {
        final refreshed = await context.push<bool>(
          '/container-management/compose-detail',
          extra: {'id': item.id, 'name': item.name},
        );
        if (refreshed == true && context.mounted) {
          final pageState = context.findAncestorStateOfType<_ContainerManagementPageState>();
          pageState?._refreshOverview();
        }
      },
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
                Text(
                  item.path.isEmpty ? l10n.containerCount(item.containerCount) : '${l10n.containerCount(item.containerCount)} · ${item.path}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppStatusChip(
                label: item.status,
                color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final refreshed = await context.push<bool>(
                    '/container-management/compose-detail',
                    extra: {'id': item.id, 'name': item.name},
                  );
                  if (refreshed == true && context.mounted) {
                    final pageState = context.findAncestorStateOfType<_ContainerManagementPageState>();
                    pageState?._refreshOverview();
                  }
                },
                icon: const Icon(Icons.visibility_outlined),
                label: Text(l10n.view),
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

  String _shortImageId() {
    final id = item.id.trim();
    if (id.isEmpty) return '--';
    return id.length > 12 ? id.substring(0, 12) : id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLatest = item.tag.toLowerCase() == 'latest';

    return AppSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusChip(
                      label: isLatest ? 'latest' : item.tag,
                      color: isLatest ? Colors.blue.shade700 : Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    AppStatusChip(
                      label: item.sizeText,
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.imageId}：${_shortImageId()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _UnavailablePlaceholder extends StatelessWidget {
  const _UnavailablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.construction_rounded,
      message: l10n.dpanelDataSourceDeveloping,
    );
  }
}

class _DockerErrorState extends StatelessWidget {
  const _DockerErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: l10n.containerDataLoadFailed,
      message: l10n.pleaseRetryLater,
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(message: label);
  }
}

class _ComposeUiItem {
  const _ComposeUiItem({
    required this.id,
    required this.name,
    required this.status,
    required this.containerCount,
    required this.containers,
    required this.path,
    required this.updatedAt,
    required this.rawStatus,
    required this.rawState,
  });

  final String id;
  final String name;
  final String status;
  final int containerCount;
  final List<DockerContainerSummary> containers;
  final String path;
  final String updatedAt;
  final String rawStatus;
  final String rawState;
}

List<_ComposeUiItem> _buildComposeProjects({
  required List<DockerComposeProjectSummary> projects,
  required List<DockerContainerSummary> containers,
  required String searchQuery,
}) {
  final containerById = <String, DockerContainerSummary>{for (final item in containers) item.id: item};
  final normalizedQuery = searchQuery.trim().toLowerCase();

  final mapped = projects.map((project) {
    final matchedContainers = project.containerIds
        .map((id) => containerById[id])
        .whereType<DockerContainerSummary>()
        .toList();

    return _ComposeUiItem(
      id: project.id,
      name: project.name,
      status: _composeStatusText(project.status),
      containerCount: project.containerIds.length,
      containers: matchedContainers,
      path: project.path,
      updatedAt: project.updatedAt,
      rawStatus: project.status,
      rawState: project.state,
    );
  }).where((item) {
    if (normalizedQuery.isEmpty) return true;
    return item.name.toLowerCase().contains(normalizedQuery) ||
        item.path.toLowerCase().contains(normalizedQuery) ||
        item.rawStatus.toLowerCase().contains(normalizedQuery) ||
        item.rawState.toLowerCase().contains(normalizedQuery);
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  return mapped;
}

String _composeStatusText(String status) {
  switch (status.toUpperCase()) {
    case 'RUNNING':
      return l10n.running;
    case 'STOPPED':
      return l10n.containerStopped;
    case 'BUILD_FAILED':
      return l10n.buildFailed;
    case 'FAILED':
      return l10n.failed;
    default:
      return status.isEmpty ? l10n.unknown : status;
  }
}
