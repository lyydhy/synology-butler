import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/transfer_task.dart';
import '../providers/transfer_providers.dart';

class TransfersPage extends ConsumerWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(transferControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('传输')),
      body: tasks.isEmpty
          ? const Center(child: Text('暂时没有传输任务'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  child: ListTile(
                    leading: Icon(task.type == TransferTaskType.upload ? Icons.upload_rounded : Icons.download_rounded),
                    title: Text(task.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(_statusText(task.status)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: task.progress.clamp(0, 1)),
                        if (task.errorMessage != null && task.errorMessage!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(task.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
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
}
