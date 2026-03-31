import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';

import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/task_scheduler.dart';
import '../providers/task_scheduler_providers.dart';

class TaskSchedulerPage extends ConsumerWidget {
  const TaskSchedulerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(scheduledTasksProvider);
    final busyIds = ref.watch(scheduledTaskBusyIdsProvider);
    

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.taskSchedulerTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(scheduledTasksProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '任务计划加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(scheduledTasksProvider),
          actionLabel: '重新加载',
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 52),
                    const SizedBox(height: 12),
                    Text(l10n.noTasks),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final busy = busyIds.contains(task.id);
              return _TaskCard(
                task: task,
                busy: busy,
                
                onRun: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(runScheduledTaskProvider)(task);
                    messenger.showSnackBar(SnackBar(content: Text(l10n.taskSubmitted)));
                  } catch (error) {
                    messenger.showSnackBar(SnackBar(content: Text('${l10n.executeFailed}：$error')));
                  }
                },
                onToggle: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(toggleScheduledTaskProvider)(task);
                    messenger.showSnackBar(SnackBar(content: Text(task.enabled ? '任务已停用' : '任务已启用')));
                  } catch (error) {
                    messenger.showSnackBar(SnackBar(content: Text('${l10n.updateFailed}：$error')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ScheduledTask task;
  final bool busy;
  
  final Future<void> Function() onRun;
  final Future<void> Function() onToggle;

  const _TaskCard({
    required this.task,
    required this.busy,
    
    required this.onRun,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledColor = task.enabled ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task.name.isEmpty ? '未命名任务' : task.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: enabledColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.enabled ? '已启用' : '已停用',
                  style: theme.textTheme.labelMedium?.copyWith(color: enabledColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaRow(label: '所有者', value: task.owner.isEmpty ? '-' : task.owner),
          _MetaRow(label: '类型', value: task.type.isEmpty ? '-' : task.type),
          _MetaRow(label: '下次执行', value: task.nextTriggerTime.isEmpty ? '-' : task.nextTriggerTime),
          _MetaRow(label: '运行中', value: task.running ? '是' : '否'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onToggle,
                icon: busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(task.enabled ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded),
                label: Text(task.enabled ? '停用' : '启用'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: busy || task.running ? null : onRun,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.executeNow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
          children: [
            TextSpan(
              text: '$label：',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
