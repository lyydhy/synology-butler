import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/transfer_task.dart';
import '../providers/transfer_providers.dart';

class TransfersPage extends ConsumerWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(transferControllerProvider);
    final uploads = tasks.where((t) => t.type == TransferTaskType.upload).toList();
    final downloads = tasks.where((t) => t.type == TransferTaskType.download).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('传输'),
          bottom: TabBar(
            tabs: [
              Tab(text: '全部 ${tasks.isEmpty ? '' : '(${tasks.length})'}'.trim()),
              Tab(text: '上传 ${uploads.isEmpty ? '' : '(${uploads.length})'}'.trim()),
              Tab(text: '下载 ${downloads.isEmpty ? '' : '(${downloads.length})'}'.trim()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TransferList(tasks: tasks),
            _TransferList(tasks: uploads),
            _TransferList(tasks: downloads),
          ],
        ),
      ),
    );
  }
}

class _TransferList extends StatelessWidget {
  const _TransferList({required this.tasks});

  final List<TransferTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('暂时没有传输任务'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isUpload = task.type == TransferTaskType.upload;
        final color = isUpload ? Colors.blue : Colors.green;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        isUpload ? Icons.upload_rounded : Icons.download_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(isUpload ? '上传' : '下载', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text(_statusText(task.status), style: TextStyle(color: _statusColor(task.status), fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: task.progress.clamp(0, 1)),
                const SizedBox(height: 10),
                Text('来源：${task.sourcePath}', maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('目标：${task.targetPath}', maxLines: 1, overflow: TextOverflow.ellipsis),
                if (task.errorMessage != null && task.errorMessage!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.status == TransferTaskStatus.success ? '结果：${task.errorMessage!}' : '原因：${task.errorMessage!}',
                    style: TextStyle(color: task.status == TransferTaskStatus.failed ? Colors.redAccent : Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusText(TransferTaskStatus status) {
    switch (status) {
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
