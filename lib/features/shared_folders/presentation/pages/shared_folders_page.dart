import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
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
        title: Text(l10n.sharedFoldersTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(sharedFoldersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: l10n.sharedFoldersLoadFailed,
          message: '$error',
          onRetry: () => ref.invalidate(sharedFoldersProvider),
          actionLabel: l10n.reload,
        ),
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_off_rounded, size: 52),
                    const SizedBox(height: 12),
                    Text(l10n.noSharedFolders),
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

String _formatSize(double bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  double size = bytes;
  while (size >= 1024 && i < units.length - 1) {
    size /= 1024;
    i++;
  }
  return '${size.toStringAsFixed(1)} ${units[i]}';
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showFolderDetail(context, folder),
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
                // 状态标签
                _buildStatusBadge(context),
              ],
            ),
            if (folder.usageText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.storage_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    folder.usageText,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // 特性标签
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (folder.encrypted)
                  _FeatureTag(icon: Icons.lock_rounded, label: l10n.statusEncrypted, color: Colors.amber),
                if (folder.isHidden)
                  _FeatureTag(icon: Icons.visibility_off_rounded, label: l10n.statusHidden, color: Colors.grey),
                if (folder.recycleBinEnabled)
                  _FeatureTag(icon: Icons.delete_outline_rounded, label: l10n.featureRecycleBin, color: Colors.green),
                if (folder.isReadOnly)
                  _FeatureTag(icon: Icons.lock_outline_rounded, label: l10n.featureReadOnly, color: Colors.orange),
                if (folder.enableShareCompress == true)
                  _FeatureTag(icon: Icons.compress_rounded, label: l10n.featureFileCompression, color: Colors.blue),
                if (folder.enableShareCow == true)
                  _FeatureTag(icon: Icons.shield_rounded, label: l10n.featureDataIntegrityProtection, color: Colors.teal),
                if (folder.unitePermission == true)
                  _FeatureTag(icon: Icons.admin_panel_settings_rounded, label: l10n.featureAdvancedPermissions, color: Colors.purple),
                if (folder.supportSnapshot == true)
                  _FeatureTag(icon: Icons.history_rounded, label: l10n.featureSnapshot, color: Colors.indigo),
                if (folder.isShareMoving == true)
                  _FeatureTag(icon: Icons.drive_file_move_rounded, label: l10n.featureMoving, color: Colors.cyan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    String status;
    Color statusColor;

    if (folder.encrypted) {
      status = l10n.statusEncrypted;
      statusColor = Colors.amber;
    } else if (folder.isHidden) {
      status = l10n.statusHidden;
      statusColor = Colors.grey;
    } else {
      status = l10n.statusNormal;
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showFolderDetail(BuildContext context, SharedFolder folder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FolderDetailSheet(folder: folder),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _FolderDetailSheet extends StatelessWidget {
  final SharedFolder folder;

  const _FolderDetailSheet({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖动条
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.folder_shared_rounded, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        folder.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DetailTile(
                      icon: Icons.label_outline_rounded,
                      label: l10n.name,
                      value: folder.name,
                    ),
                    _DetailTile(
                      icon: Icons.description_outlined,
                      label: l10n.description,
                      value: folder.description.isEmpty ? l10n.none : folder.description,
                    ),
                    _DetailTile(
                      icon: Icons.folder_outlined,
                      label: l10n.path,
                      value: folder.volumeName != null
                          ? '${folder.volumeName}${folder.volumeDesc != null && folder.volumeDesc!.isNotEmpty ? ' (${folder.volumeDesc})' : ''}'
                          : folder.volumePath,
                    ),
                    if (folder.fileSystem.isNotEmpty)
                      _DetailTile(
                        icon: Icons.storage_outlined,
                        label: l10n.fileSystem,
                        value: folder.fileSystem,
                      ),
                    if (folder.usageText.isNotEmpty)
                      _DetailTile(
                        icon: Icons.pie_chart_outline_rounded,
                        label: l10n.spaceUsage,
                        value: folder.usageText,
                      ),
                    if (folder.quotaValue != null && folder.quotaValue! > 0)
                      _DetailTile(
                        icon: Icons.data_usage_rounded,
                        label: l10n.quota,
                        value: '${_formatSize((folder.quotaValue! * 1024 * 1024).toDouble())}（已用 ${_formatSize((folder.shareQuotaUsed ?? 0) * 1024 * 1024)}）',
                      ),
                    const SizedBox(height: 16),
                    // 特性标签（与卡片一致）
                    if (folder.encrypted || folder.isHidden || folder.recycleBinEnabled || folder.isReadOnly ||
                        folder.enableShareCompress == true || folder.enableShareCow == true ||
                        folder.unitePermission == true || folder.supportSnapshot == true ||
                        folder.isShareMoving == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.features,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (folder.encrypted)
                                _FeatureTag(icon: Icons.lock_rounded, label: l10n.statusEncrypted, color: Colors.amber),
                              if (folder.isHidden)
                                _FeatureTag(icon: Icons.visibility_off_rounded, label: l10n.statusHidden, color: Colors.grey),
                              if (folder.recycleBinEnabled)
                                _FeatureTag(icon: Icons.delete_outline_rounded, label: l10n.featureRecycleBin, color: Colors.green),
                              if (folder.isReadOnly)
                                _FeatureTag(icon: Icons.lock_outline_rounded, label: l10n.featureReadOnly, color: Colors.orange),
                              if (folder.enableShareCompress == true)
                                _FeatureTag(icon: Icons.compress_rounded, label: l10n.featureFileCompression, color: Colors.blue),
                              if (folder.enableShareCow == true)
                                _FeatureTag(icon: Icons.shield_rounded, label: l10n.featureDataIntegrityProtection, color: Colors.teal),
                              if (folder.unitePermission == true)
                                _FeatureTag(icon: Icons.admin_panel_settings_rounded, label: l10n.featureAdvancedPermissions, color: Colors.purple),
                              if (folder.supportSnapshot == true)
                                _FeatureTag(icon: Icons.history_rounded, label: l10n.featureSnapshot, color: Colors.indigo),
                              if (folder.isShareMoving == true)
                                _FeatureTag(icon: Icons.drive_file_move_rounded, label: l10n.featureMoving, color: Colors.cyan),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
