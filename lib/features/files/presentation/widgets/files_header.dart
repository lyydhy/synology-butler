import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'path_breadcrumb.dart';

class FilesHeader extends StatelessWidget {
  const FilesHeader({
    super.key,
    required this.path,
    required this.sort,
    required this.canGoUp,
    required this.onRefresh,
    required this.onSortSelected,
    required this.onTapSegment,
    required this.onGoUp,
    required this.onUpload,
    required this.onCreateFolder,
    this.title = '文件管理',
    this.showActionMenu = true,
  });

  final String path;
  final String sort;
  final bool canGoUp;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSortSelected;
  final ValueChanged<String> onTapSegment;
  final VoidCallback onGoUp;
  final VoidCallback onUpload;
  final VoidCallback onCreateFolder;
  final String title;
  final bool showActionMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.folder_open_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (showActionMenu)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (value) {
                    switch (value) {
                      case 'upload':
                        onUpload();
                        break;
                      case 'create_folder':
                        onCreateFolder();
                        break;
                      case 'sort_name':
                        onSortSelected('name');
                        break;
                      case 'sort_size':
                        onSortSelected('size');
                        break;
                      case 'refresh':
                        onRefresh();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'upload', child: Text(l10n.uploadFile)),
                    PopupMenuItem(value: 'create_folder', child: Text(l10n.createFolder)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'sort_name', child: Text(l10n.sortByName)),
                    PopupMenuItem(value: 'sort_size', child: Text(l10n.sortBySize)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'refresh', child: Text(l10n.retry)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          PathBreadcrumb(path: path, onTapSegment: onTapSegment),
          if (canGoUp) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onGoUp,
              icon: const Icon(Icons.arrow_upward_rounded),
              label: Text(l10n.goParent),
            ),
          ],
        ],
      ),
    );
  }
}
