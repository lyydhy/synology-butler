import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_launcher.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../domain/entities/transfer_task.dart';
import '../providers/transfer_providers.dart';

enum _TransferFilter { all, active, success, failed }

class TransfersPage extends ConsumerStatefulWidget {
  const TransfersPage({super.key});

  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> {
  _TransferFilter _filter = _TransferFilter.all;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(transferControllerProvider);
    final controller = ref.read(transferControllerProvider.notifier);

    final activeTasks = tasks
        .where((t) => t.status == TransferTaskStatus.running || t.status == TransferTaskStatus.queued)
        .toList();
    final successTasks = tasks.where((t) => t.status == TransferTaskStatus.success).toList();
    final failedTasks = tasks.where((t) => t.status == TransferTaskStatus.failed).toList();

    final filteredTasks = switch (_filter) {
      _TransferFilter.all => tasks,
      _TransferFilter.active => activeTasks,
      _TransferFilter.success => successTasks,
      _TransferFilter.failed => failedTasks,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transfersTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_success') controller.clearCompleted();
              if (value == 'clear_failed') controller.clearFailed();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'clear_success', child: Text(l10n.clearCompleted)),
              PopupMenuItem(value: 'clear_failed', child: Text(l10n.clearFailed)),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _OverviewCard(
                totalCount: tasks.length,
                activeCount: activeTasks.length,
                successCount: successTasks.length,
                failedCount: failedTasks.length,
                onClearSuccess: controller.clearCompleted,
                onClearFailed: controller.clearFailed,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TransferFilterHeaderDelegate(
              minExtent: 52,
              maxExtent: 52,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: l10n.filterAll,
                        count: tasks.length,
                        selected: _filter == _TransferFilter.all,
                        onTap: () => setState(() => _filter = _TransferFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.filterActive,
                        count: activeTasks.length,
                        selected: _filter == _TransferFilter.active,
                        onTap: () => setState(() => _filter = _TransferFilter.active),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.filterCompleted,
                        count: successTasks.length,
                        selected: _filter == _TransferFilter.success,
                        onTap: () => setState(() => _filter = _TransferFilter.success),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.filterFailed,
                        count: failedTasks.length,
                        selected: _filter == _TransferFilter.failed,
                        onTap: () => setState(() => _filter = _TransferFilter.failed),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
          _TransferSectionList(tasks: filteredTasks),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.totalCount,
    required this.activeCount,
    required this.successCount,
    required this.failedCount,
    required this.onClearSuccess,
    required this.onClearFailed,
  });

  final int totalCount;
  final int activeCount;
  final int successCount;
  final int failedCount;
  final VoidCallback onClearSuccess;
  final VoidCallback onClearFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.swap_vert_rounded, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近传输',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCount == 0 ? '还没有任务，新的上传和下载会显示在这里' : '优先看进行中和失败任务，已完成记录可以随时清理',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _OverviewMetric(label: l10n.filterActive, value: '$activeCount', color: Colors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _OverviewMetric(label: l10n.filterCompleted, value: '$successCount', color: Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _OverviewMetric(label: l10n.filterFailed, value: '$failedCount', color: Colors.redAccent)),
            ],
          ),
          if (successCount > 0 || failedCount > 0) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (successCount > 0)
                  OutlinedButton.icon(
                    onPressed: onClearSuccess,
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l10n.deleteCompleted),
                  ),
                if (failedCount > 0)
                  OutlinedButton.icon(
                    onPressed: onClearFailed,
                    icon: const Icon(Icons.error_outline_rounded),
                    label: Text(l10n.deleteFailedRecords),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest;
    final foreground = selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.14)
                      : theme.colorScheme.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferSectionList extends StatelessWidget {
  const _TransferSectionList({required this.tasks});

  final List<TransferTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 42, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  '这个筛选下暂时没有传输任务',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '新的上传、下载、失败重试都会出现在这里。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final active = tasks.where((t) => t.status == TransferTaskStatus.running || t.status == TransferTaskStatus.queued).toList();
    final success = tasks.where((t) => t.status == TransferTaskStatus.success).toList();
    final failed = tasks.where((t) => t.status == TransferTaskStatus.failed).toList();
    final children = <Widget>[
      if (active.isNotEmpty) ...[
        _SectionHeader(title: l10n.filterActive, count: active.length),
        const SizedBox(height: 10),
        ...active.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransferTaskCard(task: task),
            )),
      ],
      if (success.isNotEmpty) ...[
        if (active.isNotEmpty) const SizedBox(height: 8),
        _SectionHeader(title: l10n.filterCompleted, count: success.length),
        const SizedBox(height: 10),
        ...success.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransferTaskCard(task: task),
            )),
      ],
      if (failed.isNotEmpty) ...[
        if (active.isNotEmpty || success.isNotEmpty) const SizedBox(height: 8),
        _SectionHeader(title: l10n.filterFailed, count: failed.length),
        const SizedBox(height: 10),
        ...failed.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TransferTaskCard(task: task),
            )),
      ],
    ];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      sliver: SliverList.list(children: children),
    );
  }
}

class _TransferFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TransferFilterHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _TransferFilterHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$count', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _TransferTaskCard extends ConsumerStatefulWidget {
  const _TransferTaskCard({required this.task});

  final TransferTask task;

  @override
  ConsumerState<_TransferTaskCard> createState() => _TransferTaskCardState();
}

class _TransferTaskCardState extends ConsumerState<_TransferTaskCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    final controller = ref.read(transferControllerProvider.notifier);
    final isUpload = task.type == TransferTaskType.upload;
    final statusColor = _statusColor(task.status);
    final progressText = _progressText(task.progress);
    final pathText = task.type == TransferTaskType.download ? task.targetPath : task.sourcePath;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (isUpload ? Colors.blue : Colors.green).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isUpload ? Icons.north_rounded : Icons.south_rounded,
                    color: isUpload ? Colors.blue : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(task),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: '更多操作',
                  onSelected: (value) async {
                    switch (value) {
                      case 'toggle':
                        setState(() => expanded = !expanded);
                        break;
                      case 'retry':
                        controller.retryTask(task);
                        break;
                      case 'remove':
                        controller.removeTask(task.id);
                        break;
                      case 'copy':
                        final text = task.status == TransferTaskStatus.failed
                            ? (task.errorMessage ?? task.targetPath)
                            : task.targetPath;
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(content: Text(task.status == TransferTaskStatus.failed ? '失败原因已复制' : '路径已复制')),
                          );
                        }
                        break;
                      case 'open':
                        try {
                          await FileLauncher.open(task.targetPath);
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.openedWithSystem)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(content: Text(ErrorMapper.map(e).message)),
                            );
                          }
                        }
                        break;
                      case 'open_dir':
                        final parent = File(task.targetPath).parent.path;
                        try {
                          await FileLauncher.open(parent);
                        } catch (_) {
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.directory(parent))),
                            );
                          }
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'toggle', child: Text(expanded ? '收起详情' : '查看详情')),
                    if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download)
                      PopupMenuItem(value: 'open', child: Text(l10n.open)),
                    if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download)
                      PopupMenuItem(value: 'open_dir', child: Text(l10n.openDirectory)),
                    if (task.status == TransferTaskStatus.failed)
                      PopupMenuItem(value: 'retry', child: Text(l10n.retry)),
                    PopupMenuItem(
                      value: 'copy',
                      child: Text(task.status == TransferTaskStatus.failed ? '复制失败原因' : '复制路径'),
                    ),
                    PopupMenuItem(value: 'remove', child: Text(l10n.removeRecord)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoBadge(
                  icon: _statusIcon(task.status),
                  label: _statusText(task),
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                _InfoBadge(
                  icon: isUpload ? Icons.upload_rounded : Icons.download_rounded,
                  label: isUpload ? '上传' : '下载',
                  color: isUpload ? Colors.blue : Colors.green,
                ),
                const Spacer(),
                Text(
                  progressText,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: task.progress.clamp(0, 1),
                minHeight: 7,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pathText,
              maxLines: expanded ? 6 : 1,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
            if (task.errorMessage != null && task.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: task.status == TransferTaskStatus.failed
                      ? Colors.redAccent.withValues(alpha: 0.08)
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  task.status == TransferTaskStatus.success ? '结果：${task.errorMessage!}' : '原因：${task.errorMessage!}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: task.status == TransferTaskStatus.failed ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (expanded) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download)
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        try {
                          await FileLauncher.open(task.targetPath);
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.openedWithSystem)),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(content: Text(ErrorMapper.map(e).message)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l10n.open),
                    ),
                  if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final parent = File(task.targetPath).parent.path;
                        try {
                          await FileLauncher.open(parent);
                        } catch (_) {
                          if (context.mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.directory(parent))),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open_outlined),
                      label: Text(l10n.openDirectory),
                    ),
                  if (task.status == TransferTaskStatus.failed)
                    FilledButton.tonalIcon(
                      onPressed: () => controller.retryTask(task),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retry),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final text = task.status == TransferTaskStatus.failed
                          ? (task.errorMessage ?? task.targetPath)
                          : task.targetPath;
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(content: Text(task.status == TransferTaskStatus.failed ? '失败原因已复制' : '路径已复制')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(task.status == TransferTaskStatus.failed ? '复制原因' : '复制路径'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.removeTask(task.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.removeRecord),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(TransferTask task) {
    if (task.type == TransferTaskType.upload) {
      return '上传到 ${task.targetPath}';
    }
    return '保存到 ${task.targetPath}';
  }

  String _progressText(double value) {
    final percent = (value.clamp(0, 1) * 100).round();
    return '$percent%';
  }

  String _statusText(TransferTask task) {
    switch (task.status) {
      case TransferTaskStatus.queued:
        return '排队中';
      case TransferTaskStatus.running:
        return '进行中';
      case TransferTaskStatus.success:
        return '已完成';
      case TransferTaskStatus.failed:
        return '失败';
    }
  }

  IconData _statusIcon(TransferTaskStatus status) {
    switch (status) {
      case TransferTaskStatus.queued:
        return Icons.schedule_rounded;
      case TransferTaskStatus.running:
        return Icons.autorenew_rounded;
      case TransferTaskStatus.success:
        return Icons.check_circle_rounded;
      case TransferTaskStatus.failed:
        return Icons.error_rounded;
    }
  }

  Color _statusColor(TransferTaskStatus status) {
    switch (status) {
      case TransferTaskStatus.queued:
        return Colors.orange;
      case TransferTaskStatus.running:
        return Colors.blue;
      case TransferTaskStatus.success:
        return Colors.green;
      case TransferTaskStatus.failed:
        return Colors.redAccent;
    }
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
