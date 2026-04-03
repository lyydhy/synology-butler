import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/index_service.dart';
import '../providers/index_service_providers.dart';

class IndexServicePage extends ConsumerWidget {
  const IndexServicePage({super.key});

  static const _qualityOptions = <int, String>{
    0: '低',
    1: '中',
    2: '高',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(indexServiceProvider);
    final busy = ref.watch(indexServiceBusyProvider);
    

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.indexServiceTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: busy ? null : () => ref.invalidate(indexServiceProvider),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '索引服务加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(indexServiceProvider),
          actionLabel: '重新加载',
        ),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _StatusCard(indexing: data.indexing, statusText: data.statusText, ),
              const SizedBox(height: 12),
              _ThumbnailQualityCard(
                currentQuality: data.thumbnailQuality,
                busy: busy,
                onChanged: (value) async {
                  if (value == null) return;
                  try {
                    await ref.read(setThumbnailQualityProvider)(value);
                    Toast.success(l10n.thumbnailQualityUpdated);
                  } catch (error) {
                    Toast.error('${l10n.updateFailed}：$error');
                  }
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                busy: busy,
                onRebuild: () async {
                  try {
                    await ref.read(rebuildIndexProvider)();
                    Toast.success(l10n.rebuildSubmitted);
                  } catch (error) {
                    Toast.error('${l10n.rebuildFailed}：$error');
                  }
                },
              ),
              const SizedBox(height: 12),
              _TaskCard(tasks: data.tasks, ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool indexing;
  final String statusText;
  

  const _StatusCard({required this.indexing, required this.statusText, });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = indexing ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(indexing ? Icons.sync_rounded : Icons.check_circle_outline_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentIndexStatus, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(statusText.isEmpty ? (indexing ? '索引进行中' : '空闲') : statusText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailQualityCard extends StatelessWidget {
  final int currentQuality;
  final bool busy;
  
  final ValueChanged<int?> onChanged;

  const _ThumbnailQualityCard({required this.currentQuality, required this.busy,  required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.thumbnailQuality, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: IndexServicePage._qualityOptions.containsKey(currentQuality) ? currentQuality : 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: IndexServicePage._qualityOptions.entries
                .map((entry) => DropdownMenuItem<int>(value: entry.key, child: Text(entry.value)))
                .toList(),
            onChanged: busy ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final bool busy;
  
  final Future<void> Function() onRebuild;

  const _ActionCard({required this.busy,  required this.onRebuild});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.rebuildIndex, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l10n.rebuildIndexDesc, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy ? null : onRebuild,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.rebuildIndex),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final List<IndexServiceTask> tasks;
  

  const _TaskCard({required this.tasks, });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.currentTask, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Text(l10n.noIndexTasks, style: theme.textTheme.bodyMedium)
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.fiber_manual_record_rounded, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${task.type} · ${task.status}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if ((task.detail ?? '').toString().isNotEmpty)
                            Text(task.detail.toString(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
