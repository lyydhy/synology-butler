import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/utils/format_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_launcher.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/transfer_task.dart';
import '../providers/transfer_providers.dart';

class TransfersPage extends ConsumerStatefulWidget {
  const TransfersPage({super.key});

  @override
  ConsumerState<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends ConsumerState<TransfersPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(transferProvider);
    final controller = ref.read(transferProvider.notifier);

    final activeTasks = tasks
        .where((t) => t.status == TransferTaskStatus.running || t.status == TransferTaskStatus.queued)
        .toList();
    final successTasks = tasks.where((t) => t.status == TransferTaskStatus.success).toList();
    final failedTasks = tasks.where((t) => t.status == TransferTaskStatus.failed).toList();

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SlidingTabBar(
              tabController: _tabController,
              tabs: [
                SlidingTabItem(icon: Icons.list_rounded, label: l10n.filterAll, badge: tasks.isEmpty ? null : '${tasks.length}'),
                SlidingTabItem(icon: Icons.autorenew_rounded, label: l10n.filterActive, badge: activeTasks.isEmpty ? null : '${activeTasks.length}'),
                SlidingTabItem(icon: Icons.check_circle_outline_rounded, label: l10n.filterCompleted, badge: successTasks.isEmpty ? null : '${successTasks.length}'),
                SlidingTabItem(icon: Icons.error_outline_rounded, label: l10n.filterFailed, badge: failedTasks.isEmpty ? null : '${failedTasks.length}'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(tasks: tasks, controller: controller),
                _TaskList(tasks: activeTasks, controller: controller),
                _TaskList(tasks: successTasks, controller: controller),
                _TaskList(tasks: failedTasks, controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatefulWidget {
  const _TaskList({required this.tasks, required this.controller});

  final List<TransferTask> tasks;
  final TransferController controller;

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + widget.tasks.length * 50),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(_TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks.length != widget.tasks.length) {
      _controller.duration = Duration(milliseconds: 400 + widget.tasks.length * 50);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 42, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                l10n.noTransfersInFilter,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.transfersAppearHere,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final start = (index * 0.08).clamp(0.0, 0.6);
        final end = (start + 0.35).clamp(0.0, 1.0);
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TransferTaskCard(task: widget.tasks[index]),
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context);
    final task = widget.task;
    final controller = ref.read(transferProvider.notifier);
    final isUpload = task.type == TransferTaskType.upload;
    final statusColor = _statusColor(task.status);
    final progressText = _progressText(task, l10n);
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
                        _subtitle(task, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: l10n.moreActions,
                  onSelected: (value) async {
                    switch (value) {
                      case 'toggle':
                        setState(() => expanded = !expanded);
                        break;
                      case 'retry':
                        controller.retryTask(task);
                        break;
                      case 'pause':
                        controller.pauseDownload(task.id);
                        break;
                      case 'resume':
                        controller.resumeDownload(task.id);
                        break;
                      case 'cancel':
                        controller.cancelDownload(task.id);
                        break;
                      case 'remove':
                        controller.removeTask(task.id);
                        break;
                      case 'remove_with_file':
                        controller.removeTask(task.id, deleteFile: true);
                        break;
                      case 'copy':
                        final text = task.status == TransferTaskStatus.failed
                            ? (task.errorMessage ?? task.targetPath)
                            : task.targetPath;
                        await Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          Toast.show(task.status == TransferTaskStatus.failed ? l10n.errorCopied : l10n.pathCopied);
                        }
                        break;
                      case 'open':
                        try {
                          await FileLauncher.open(task.targetPath);
                          if (context.mounted) {
                            Toast.show(l10n.openedWithSystem);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Toast.error(ErrorMapper.map(e).message);
                          }
                        }
                        break;
                      case 'open_dir':
                        final parent = File(task.targetPath).parent.path;
                        try {
                          final success = await FileLauncher.openDirectory(parent);
                          if (!success && context.mounted) {
                            Toast.show(l10n.directory(parent));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Toast.show(l10n.directory(parent));
                          }
                        }
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'toggle', child: Text(expanded ? l10n.collapseDetails : l10n.viewDetails)),
                    if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download)
                      PopupMenuItem(value: 'open', child: Text(l10n.open)),
                    if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download && FileLauncher.supportsOpenDirectory)
                      PopupMenuItem(value: 'open_dir', child: Text(l10n.openDirectory)),
                    if (task.status == TransferTaskStatus.failed)
                      PopupMenuItem(value: 'retry', child: Text(l10n.retry)),
                    if (task.type == TransferTaskType.download && task.status == TransferTaskStatus.running)
                      PopupMenuItem(value: 'pause', child: Text(l10n.pause)),
                    if (task.type == TransferTaskType.download && task.status == TransferTaskStatus.paused)
                      PopupMenuItem(value: 'resume', child: Text(l10n.resume)),
                    if (task.type == TransferTaskType.download && (task.status == TransferTaskStatus.running || task.status == TransferTaskStatus.paused))
                      PopupMenuItem(value: 'cancel', child: Text(l10n.cancel)),
                    PopupMenuItem(
                      value: 'copy',
                      child: Text(task.status == TransferTaskStatus.failed ? l10n.copyErrorReason : l10n.copyPath),
                    ),
                    PopupMenuItem(value: 'remove', child: Text(l10n.removeRecord)),
                    if (task.type == TransferTaskType.download && task.status == TransferTaskStatus.success)
                      PopupMenuItem(value: 'remove_with_file', child: Text(l10n.removeRecordAndFile)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoBadge(
                  icon: _statusIcon(task.status),
                  label: _statusText(task, l10n),
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                _InfoBadge(
                  icon: isUpload ? Icons.upload_rounded : Icons.download_rounded,
                  label: isUpload ? l10n.upload : l10n.download,
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
                  task.status == TransferTaskStatus.success ? l10n.resultLabel(task.errorMessage!) : l10n.reasonLabel(task.errorMessage!),
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
                            Toast.show(l10n.openedWithSystem);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Toast.error(ErrorMapper.map(e).message);
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l10n.open),
                    ),
                  if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download && FileLauncher.supportsOpenDirectory)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final parent = File(task.targetPath).parent.path;
                        try {
                          final success = await FileLauncher.openDirectory(parent);
                          if (!success && context.mounted) {
                            Toast.show(l10n.directory(parent));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Toast.show(l10n.directory(parent));
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
                        Toast.show(task.status == TransferTaskStatus.failed ? l10n.errorCopied : l10n.pathCopied);
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(task.status == TransferTaskStatus.failed ? l10n.copyReason : l10n.copyPath),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.removeTask(task.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.removeRecord),
                  ),
                  if (task.type == TransferTaskType.download && task.status == TransferTaskStatus.success)
                    OutlinedButton.icon(
                      onPressed: () => controller.removeTask(task.id, deleteFile: true),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: Text(l10n.removeRecordAndFile),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(TransferTask task, AppLocalizations l10n) {
    if (task.type == TransferTaskType.upload) {
      return l10n.uploadTo(task.targetPath);
    }
    return l10n.saveTo(task.targetPath);
  }

  String _progressText(TransferTask task, AppLocalizations l10n) {
    // 显示字节进度
    if (task.totalBytes > 0 && task.receivedBytes > 0) {
      final received = formatBytes(task.receivedBytes);
      final total = formatBytes(task.totalBytes);
      return '$received / $total';
    }
    // 回退到百分比
    final percent = (task.progress.clamp(0, 1) * 100).round();
    return '$percent%';
  }


  String _statusText(TransferTask task, AppLocalizations l10n) {
    switch (task.status) {
      case TransferTaskStatus.queued:
        return l10n.statusQueued;
      case TransferTaskStatus.running:
        return l10n.statusRunning;
      case TransferTaskStatus.paused:
        return l10n.statusPaused;
      case TransferTaskStatus.success:
        return l10n.statusCompleted;
      case TransferTaskStatus.failed:
        return l10n.statusFailed;
    }
  }

  IconData _statusIcon(TransferTaskStatus status) {
    switch (status) {
      case TransferTaskStatus.queued:
        return Icons.schedule_rounded;
      case TransferTaskStatus.running:
        return Icons.autorenew_rounded;
      case TransferTaskStatus.paused:
        return Icons.pause_circle_rounded;
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
      case TransferTaskStatus.paused:
        return Colors.amber;
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
