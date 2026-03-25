import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/download_status_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../../domain/entities/download_task.dart';
import '../providers/download_providers.dart';
import '../widgets/download_task_detail_sheet.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  Future<void> _showAddTaskDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
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

  Future<void> _handleTaskAction(BuildContext context, WidgetRef ref, DownloadTask task, String action) async {
    final l10n = AppLocalizations.of(context);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(activeServerProvider);
    final currentSession = ref.watch(activeSessionProvider);

    if (currentServer == null || currentSession == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.downloadsTitle)), body: Center(child: Text(l10n.noSessionPleaseLogin)));
    }

    final filter = ref.watch(downloadFilterProvider);
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
                ChoiceChip(label: Text(l10n.downloadFilterAll), selected: filter == 'all', onSelected: (_) => ref.read(downloadFilterProvider.notifier).state = 'all'),
                ChoiceChip(label: Text(l10n.downloadFilterDownloading), selected: filter == 'downloading', onSelected: (_) => ref.read(downloadFilterProvider.notifier).state = 'downloading'),
                ChoiceChip(label: Text(l10n.downloadFilterPaused), selected: filter == 'paused', onSelected: (_) => ref.read(downloadFilterProvider.notifier).state = 'paused'),
                ChoiceChip(label: Text(l10n.downloadFilterFinished), selected: filter == 'finished', onSelected: (_) => ref.read(downloadFilterProvider.notifier).state = 'finished'),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(child: Text(l10n.noTasksForFilter));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(downloadListProvider),
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
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
                            onSelected: (value) => _handleTaskAction(context, ref, task, value),
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
                      FilledButton(onPressed: () => ref.invalidate(downloadListProvider), child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddTaskDialog(context, ref), child: const Icon(Icons.add)),
    );
  }
}
