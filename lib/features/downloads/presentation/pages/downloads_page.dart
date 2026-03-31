import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/download_status_helper.dart';
import '../../../../core/utils/l10n.dart';
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

  /// 当前页面使用的下载任务筛选条件。
  String _selectedFilter = _allFilter;

  /// 弹出新建下载任务对话框。
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

  /// 展示下载任务详情面板。
  void _showTaskDetail(BuildContext context, DownloadTask task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DownloadTaskDetailSheet(task: task),
    );
  }

  /// 执行下载任务操作，例如暂停、恢复、删除。
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
                content: Text('确定要删除“${task.title}”吗？'),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.operationSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
      }
    }
  }

  /// 根据页面当前筛选条件过滤下载任务。
  List<DownloadTask> _filterTasks(List<DownloadTask> tasks) {
    if (_selectedFilter == _allFilter) {
      return tasks;
    }
    return tasks.where((task) => task.status == _selectedFilter).toList();
  }

  /// 刷新下载任务列表。
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

    final tasksAsync = ref.watch(downloadListProvider);

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
                  selected: _selectedFilter == _allFilter,
                  onSelected: (_) => setState(() => _selectedFilter = _allFilter),
                ),
                ChoiceChip(
                  label: Text(l10n.downloadFilterDownloading),
                  selected: _selectedFilter == _downloadingFilter,
                  onSelected: (_) => setState(() => _selectedFilter = _downloadingFilter),
                ),
                ChoiceChip(
                  label: Text(l10n.downloadFilterPaused),
                  selected: _selectedFilter == _pausedFilter,
                  onSelected: (_) => setState(() => _selectedFilter = _pausedFilter),
                ),
                ChoiceChip(
                  label: Text(l10n.downloadFilterFinished),
                  selected: _selectedFilter == _finishedFilter,
                  onSelected: (_) => setState(() => _selectedFilter = _finishedFilter),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final visibleTasks = _filterTasks(tasks);
                if (visibleTasks.isEmpty) {
                  return Center(child: Text(l10n.noTasksForFilter));
                }
                return RefreshIndicator(
                  onRefresh: _refreshTasks,
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
                              Text('状态：${DownloadStatusHelper.toDisplayText(task.status)}'),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: task.progress.clamp(0, 1)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleTaskAction(context, task, value),
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
                          onTap: () => _showTaskDetail(context, task),
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
                      Text('加载下载任务失败：${ErrorMapper.map(error).message}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _refreshTasks, child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddTaskDialog(context), child: const Icon(Icons.add)),
    );
  }
}
