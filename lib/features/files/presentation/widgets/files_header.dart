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
  });

  final String path;
  final String sort;
  final bool canGoUp;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSortSelected;
  final ValueChanged<String> onTapSegment;
  final VoidCallback onGoUp;

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
        border: Border.all(color: theme.dividerColor.withOpacity(0.10)),
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
                    Text('文件管理', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.swap_vert_rounded),
                initialValue: sort,
                onSelected: onSortSelected,
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'name', child: Text(l10n.sortByName)),
                  PopupMenuItem(value: 'size', child: Text(l10n.sortBySize)),
                ],
              ),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
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
