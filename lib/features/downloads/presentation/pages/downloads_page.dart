import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/download_status_helper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../providers/download_providers.dart';
import '../widgets/download_task_detail_sheet.dart';

/// 下载任务页面。
///
/// 筛选条件只影响当前页面展示，因此回归 Flutter 原生 State。
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  static const String _allFilter = 'all';
  static const String _downloadingFilter = 'downloading';
  static const String _pausedFilter = 'paused';
  static const String _finishedFilter = 'finished';

  String _selectedFilter = _allFilter;

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.createDownloadTask),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: l10n.downloadLinkOrMagnet),
                maxLines: 3,
              ),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: isSubmitting ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final uri = controller.text.trim();
                      if (uri.isEmpty) {
                        setState(() => errorText = l10n.downloadLinkOrMagnet);
                        return;
                      }
                      setState(() {
                        isSubmitting = true;
                        errorText = null;
                      });
                      try {
                        await ref.read(downloadActionProvider)(uri);
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        setState(() {
                          errorText = ErrorMapper.map(e).message;
                          isSubmitting = false;
                        });
                      }
                    },
              child: Text(isSubmitting ? l10n.submitting : l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetail(BuildContext context, DownloadTask task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DownloadTaskDetailSheet(task: task),
    );
  }

  Future<void> _handleTaskAction(BuildContext context, DownloadTask task, String action) async {
    try {
      if (action == 'detail') {
        _showTaskDetail(context, task);
        return;
      }
      if (action == 'pause') {
        await ref.read(downloadPauseProvider)(task.id);
      } else if (action == 'resume') {
        await ref.read(downloadResumeProvider)(task.id);
      } else if (action == 'delete') {
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.deleteTask),
                content: Text('l10n.confirmDeleteDownloadTask(task.title)'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                  FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteConfirm)),
                ],
              ),
            ) ??
            false;
        if (!confirmed) return;
        await ref.read(downloadDeleteProvider)(task.id);
      }
      if (context.mounted) {
        Toast.success(l10n.operationSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        Toast.error(ErrorMapper.map(e).message);
      }
    }
  }

  List<DownloadTask> _filterTasks(List<DownloadTask> tasks) {
    if (_selectedFilter == _allFilter) return tasks;
    return tasks.where((task) => task.status == _selectedFilter).toList();
  }

  Future<void> _refreshTasks() async {
    ref.invalidate(downloadListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(currentConnectionProvider);
    final currentServer = connection.server;
    final currentSession = connection.session;

    if (currentServer == null || currentSession == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.downloadsTitle)), body: Center(child: Text(l10n.noSessionPleaseLogin)));
    }

    final availableAsync = ref.watch(downloadStationAvailableProvider);

    return availableAsync.when(
      loading: () => Scaffold(appBar: AppBar(title: Text(l10n.downloadsTitle)), body: const Center(child: CircularProgressIndicator())),
      error: (_, __) => _NotInstalledView(onRetry: () => ref.invalidate(downloadStationAvailableProvider)),
      data: (available) {
        if (!available) {
          return Scaffold(appBar: AppBar(title: Text(l10n.downloadsTitle)), body: _NotInstalledView(onRetry: () => ref.invalidate(downloadStationAvailableProvider)));
        }
        return _DownloadContent(
          selectedFilter: _selectedFilter,
          onFilterChanged: (f) => setState(() => _selectedFilter = f),
          onRefresh: _refreshTasks,
          onShowAddDialog: () => _showAddTaskDialog(context),
          onHandleAction: (task, action) => _handleTaskAction(context, task, action),
          tasksAsync: ref.watch(downloadListProvider),
          filterTasks: _filterTasks,
        );
      },
    );
  }
}

class _NotInstalledView extends StatelessWidget {
  const _NotInstalledView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text('Download Station ${l10n.notInstalled}', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '请在群晖 NAS 上安装 Download Station 套件',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _DownloadContent extends StatelessWidget {
  const _DownloadContent({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onShowAddDialog,
    required this.onHandleAction,
    
    required this.tasksAsync,
    required this.filterTasks,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onShowAddDialog;
  final Future<void> Function(DownloadTask, String) onHandleAction;
  final AsyncValue<List<DownloadTask>> tasksAsync;
  final List<DownloadTask> Function(List<DownloadTask>) filterTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.downloadFilterAll),
                  selected: selectedFilter == 'all',
                  onSelected: (_) => onFilterChanged('all'),
                ),
                ChoiceChip(
                  label: Text(l10n.downloadFilterDownloading),
                  selected: selectedFilter == 'downloading',
                  onSelected: (_) => onFilterChanged('downloading'),
                ),
                ChoiceChip(
                  label: Text(l10n.downloadFilterPaused),
                  selected: selectedFilter == 'paused',
                  onSelected: (_) => onFilterChanged('paused'),
                ),
                ChoiceChip(
                  label: Text(l10n.downloadFilterFinished),
                  selected: selectedFilter == 'finished',
                  onSelected: (_) => onFilterChanged('finished'),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final visibleTasks = filterTasks(tasks);
                if (visibleTasks.isEmpty) {
                  return Center(child: Text(l10n.noTasksForFilter));
                }
                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    itemCount: visibleTasks.length,
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      final isPaused = task.status == 'paused';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${l10n.status}：${DownloadStatusHelper.toDisplayText(task.status)}'),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: task.progress.clamp(0, 1)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => onHandleAction(task, value),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'detail', child: Text(l10n.detail)),
                              PopupMenuItem(value: isPaused ? 'resume' : 'pause', child: Text(isPaused ? l10n.resume : l10n.pause)),
                              PopupMenuItem(value: 'delete', child: Text(l10n.deleteConfirm)),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text('${(task.progress * 100).toStringAsFixed(0)}%'),
                            ),
                          ),
                          onTap: () => _showTaskDetailSheet(context, task),
                        ),
                      );
                    },
                  ),
                );
              },
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${l10n.downloadTasksLoadFailed}：${ErrorMapper.map(error).message}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: onRefresh, child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: onShowAddDialog, child: const Icon(Icons.add)),
    );
  }

  void _showTaskDetailSheet(BuildContext context, DownloadTask task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DownloadTaskDetailSheet(task: task),
    );
  }
}
