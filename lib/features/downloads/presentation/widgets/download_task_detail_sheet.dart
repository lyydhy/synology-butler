import 'package:flutter/material.dart';

import '../../../../core/utils/download_status_helper.dart';
import '../../../../domain/entities/download_task.dart';
import '../../../../core/utils/l10n.dart';

class DownloadTaskDetailSheet extends StatelessWidget {
  const DownloadTaskDetailSheet({
    super.key,
    required this.task,
  });

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag_outlined),
                title: Text(l10n.taskId),
                subtitle: Text(task.id),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sync_outlined),
                title: Text(l10n.status),
                subtitle: Text(DownloadStatusHelper.toDisplayText(task.status)),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.percent_outlined),
                title: Text(l10n.progress),
                subtitle: Text('${(task.progress * 100).toStringAsFixed(0)}%'),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
