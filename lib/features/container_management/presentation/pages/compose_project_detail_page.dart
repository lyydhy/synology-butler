import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../data/api/docker_api.dart';

class ComposeProjectDetailPage extends StatefulWidget {
  const ComposeProjectDetailPage({super.key, required this.id, required this.name});

  final String id;
  final String name;

  @override
  State<ComposeProjectDetailPage> createState() => _ComposeProjectDetailPageState();
}

class _ComposeProjectDetailPageState extends State<ComposeProjectDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<DockerComposeProjectDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _detailFuture = DsmDockerApi().fetchProjectDetail(id: widget.id);
  }

  void _refresh() {
    setState(() {
      _detailFuture = DsmDockerApi().fetchProjectDetail(id: widget.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            tooltip: '构建并启动',
            onPressed: () => context.push(
              '/container-management/compose-build-logs',
              extra: {'id': widget.id, 'name': widget.name, 'mode': 'build'},
            ),
            icon: const Icon(Icons.play_circle_outline_rounded),
          ),
          IconButton(
            tooltip: '停止项目',
            onPressed: () => context.push(
              '/container-management/compose-build-logs',
              extra: {'id': widget.id, 'name': widget.name, 'mode': 'stop'},
            ),
            icon: const Icon(Icons.stop_circle_outlined),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              height: 54,
              iconSize: 18,
              fontSize: 13,
              tabs: const [
                SlidingTabItem(icon: Icons.inventory_2_outlined, label: '容器'),
                SlidingTabItem(icon: Icons.query_stats_rounded, label: '统计数据'),
                SlidingTabItem(icon: Icons.code_rounded, label: 'YAML'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<DockerComposeProjectDetail>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ComposeProjectErrorState(onRetry: _refresh);
                }
                final detail = snapshot.data!;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _ComposeContainersTab(detail: detail),
                    const AppEmptyState(
                      icon: Icons.construction_rounded,
                      message: '统计数据待开发',
                    ),
                    _ComposeYamlTab(detail: detail),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeContainersTab extends StatelessWidget {
  const _ComposeContainersTab({required this.detail});

  final DockerComposeProjectDetail detail;

  String _statusText(Map<String, dynamic> container) {
    final state = container['State'];
    if (state is Map) {
      final status = (state['Status'] ?? '').toString();
      if (status.isNotEmpty) return status;
    }
    return '--';
  }

  String _imageText(Map<String, dynamic> container) {
    final config = container['Config'];
    if (config is Map) {
      final image = (config['Image'] ?? '').toString();
      if (image.isNotEmpty) return image;
    }
    return (container['Image'] ?? '--').toString();
  }

  String _nameText(Map<String, dynamic> container) {
    final raw = (container['Name'] ?? '').toString();
    if (raw.startsWith('/')) return raw.substring(1);
    return raw.isEmpty ? '--' : raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ComposeProjectInfoCard(detail: detail),
        const SizedBox(height: 12),
        if (detail.containers.isEmpty)
          const AppEmptyState(message: '暂无项目容器数据')
        else
          ...detail.containers.map((container) {
            final status = _statusText(container);
            final isRunning = status.toLowerCase() == 'running';
            final name = _nameText(container);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        AppStatusChip(
                          label: isRunning ? '运行中' : status,
                          color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('镜像：${_imageText(container)}', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      '容器 ID：${(container['Id'] ?? '--').toString()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: name == '--'
                            ? null
                            : () => context.push('/container-management/detail', extra: {'name': name}),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('查看容器详情'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ComposeProjectInfoCard extends StatelessWidget {
  const _ComposeProjectInfoCard({required this.detail});

  final DockerComposeProjectDetail detail;

  String _statusText() {
    switch (detail.status.toUpperCase()) {
      case 'RUNNING':
        return '运行中';
      case 'STOPPED':
        return '已停止';
      case 'BUILD_FAILED':
        return '构建失败';
      default:
        return detail.status.isEmpty ? '未知' : detail.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = _statusText();
    final isRunning = statusText == '运行中';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppStatusChip(
                label: statusText,
                color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('路径：${detail.path.isEmpty ? '--' : detail.path}'),
          const SizedBox(height: 6),
          Text('共享路径：${detail.sharePath.isEmpty ? '--' : detail.sharePath}'),
          const SizedBox(height: 6),
          Text('更新时间：${detail.updatedAt.isEmpty ? '--' : detail.updatedAt}'),
          if (detail.state.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('状态细节：${detail.state}'),
          ],
        ],
      ),
    );
  }
}

class _ComposeYamlTab extends StatelessWidget {
  const _ComposeYamlTab({required this.detail});

  final DockerComposeProjectDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.content.trim().isEmpty) {
      return const AppEmptyState(message: '暂无 YAML 配置');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText(detail.content),
      ],
    );
  }
}

class _ComposeProjectErrorState extends StatelessWidget {
  const _ComposeProjectErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Compose 项目详情加载失败',
      onRetry: onRetry,
      actionLabel: '重新加载',
    );
  }
}
