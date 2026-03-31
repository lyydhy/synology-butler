import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/shared_folder.dart';
import '../providers/shared_folders_providers.dart';

class SharedFoldersPage extends ConsumerWidget {
  const SharedFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(sharedFoldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('共享文件夹'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => ref.invalidate(sharedFoldersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '共享文件夹加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(sharedFoldersProvider),
          actionLabel: '重新加载',
        ),
        data: (folders) {
          if (folders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off_rounded, size: 52),
                    SizedBox(height: 12),
                    Text('当前没有共享文件夹'),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _FolderCard(folder: folder);
            },
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final SharedFolder folder;

  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = folder.encrypted
        ? Colors.amber
        : folder.isHidden
            ? Colors.grey
            : Colors.blue;

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
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  folder.encrypted
                      ? Icons.lock_rounded
                      : folder.isHidden
                          ? Icons.visibility_off_rounded
                          : Icons.folder_shared_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      folder.description.isEmpty ? folder.volumePath : folder.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (folder.isReadOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '只读',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _MetaRow(label: '路径', value: folder.volumePath),
          if (folder.fileSystem.isNotEmpty) _MetaRow(label: '文件系统', value: folder.fileSystem),
          if (folder.usageText.isNotEmpty) _MetaRow(label: '使用量', value: folder.usageText),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (folder.isHidden)
                const _TagChip(label: '隐藏', color: Colors.grey),
              if (folder.recycleBinEnabled)
                const _TagChip(label: '回收站', color: Colors.green),
              if (folder.encrypted)
                const _TagChip(label: '加密', color: Colors.amber),
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
    if (value.isEmpty) return const SizedBox.shrink();
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

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
