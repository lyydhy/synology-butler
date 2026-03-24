import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_launcher.dart';
import '../../../../domain/entities/transfer_task.dart';
import '../providers/transfer_providers.dart';

class TransfersPage extends ConsumerWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(transferControllerProvider);
    final uploads = tasks.where((t) => t.type == TransferTaskType.upload).toList();
    final downloads = tasks.where((t) => t.type == TransferTaskType.download).toList();
    final running = tasks.where((t) => t.status == TransferTaskStatus.running || t.status == TransferTaskStatus.queued).length;
    final success = tasks.where((t) => t.status == TransferTaskStatus.success).length;
    final failed = tasks.where((t) => t.status == TransferTaskStatus.failed).length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('传输'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                final controller = ref.read(transferControllerProvider.notifier);
                if (value == 'clear_success') controller.clearCompleted();
                if (value == 'clear_failed') controller.clearFailed();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'clear_success', child: Text('清除已完成')),
                PopupMenuItem(value: 'clear_failed', child: Text('清除失败')),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: '全部 ${tasks.isEmpty ? '' : '(${tasks.length})'}'.trim()),
              Tab(text: '上传 ${uploads.isEmpty ? '' : '(${uploads.length})'}'.trim()),
              Tab(text: '下载 ${downloads.isEmpty ? '' : '(${downloads.length})'}'.trim()),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '传输中心',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '集中查看上传、下载、失败原因和结果路径',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _SummaryChip(label: '进行中', value: '$running', color: Colors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _SummaryChip(label: '已完成', value: '$success', color: Colors.green)),
                        const SizedBox(width: 8),
                        Expanded(child: _SummaryChip(label: '失败', value: '$failed', color: Colors.redAccent)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TransferList(tasks: tasks),
                  _TransferList(tasks: uploads),
                  _TransferList(tasks: downloads),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _TransferList extends ConsumerWidget {
  const _TransferList({required this.tasks});

  final List<TransferTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const Center(child: Text('暂时没有传输任务'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isUpload = task.type == TransferTaskType.upload;
        final typeColor = isUpload ? Colors.blue : Colors.green;
        final statusColor = _statusColor(task.status);
        final statusText = _statusText(task);
        final controller = ref.read(transferControllerProvider.notifier);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(isUpload ? Icons.upload_rounded : Icons.download_rounded, color: typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(isUpload ? '上传任务' : '下载任务', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: task.progress.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 12),
              _MetaLine(label: '来源', value: task.sourcePath),
              const SizedBox(height: 6),
              _MetaLine(label: '目标', value: task.targetPath),
              if (task.errorMessage != null && task.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  task.status == TransferTaskStatus.success ? '结果：${task.errorMessage!}' : '原因：${task.errorMessage!}',
                  style: TextStyle(color: task.status == TransferTaskStatus.failed ? Colors.redAccent : Colors.grey.shade700, height: 1.4),
                ),
              ],
              const SizedBox(height: 12),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已调用系统打开方式')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ErrorMapper.map(e).message)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('打开'),
                    ),
                  if (task.status == TransferTaskStatus.success && task.type == TransferTaskType.download)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final parent = File(task.targetPath).parent.path;
                        try {
                          await FileLauncher.open(parent);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('目录：$parent')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('打开目录'),
                    ),
                  if (task.status == TransferTaskStatus.failed)
                    FilledButton.tonalIcon(
                      onPressed: () => controller.retryTask(task),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('重试'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final text = task.status == TransferTaskStatus.failed
                          ? (task.errorMessage ?? task.targetPath)
                          : task.targetPath;
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('内容已复制')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: Text(task.status == TransferTaskStatus.failed ? '复制原因' : '复制路径'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => controller.removeTask(task.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('移除记录'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _statusText(TransferTask task) {
    switch (task.status) {
      case TransferTaskStatus.queued:
        return '排队中';
      case TransferTaskStatus.running:
        final percent = (task.progress.clamp(0, 1) * 100).round();
        return '进行中 $percent%';
      case TransferTaskStatus.success:
        return '已完成';
      case TransferTaskStatus.failed:
        return '失败';
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
