import 'package:flutter/material.dart';

import '../../../../core/utils/l10n.dart';
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 操作按钮行：排序 + 新建文件夹 + 上传 + 菜单
          Row(
            children: [
              // 排序胶囊
              _SortChip(sort: sort, onSortSelected: onSortSelected),
              const Spacer(),
              // 新建文件夹
              if (showActionMenu)
                IconButton(
                  tooltip: l10n.createFolder,
                  onPressed: onCreateFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  iconSize: 22,
                ),
              // 上传
              if (showActionMenu)
                IconButton(
                  tooltip: l10n.uploadFile,
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_outlined),
                  iconSize: 22,
                ),
              // 刷新
              IconButton(
                tooltip: l10n.refresh,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 22,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 面包屑路径（可点击跳转）
          PathBreadcrumb(
            path: path,
            onTapSegment: onTapSegment,
            onGoUp: canGoUp ? onGoUp : null,
          ),
        ],
      ),
    );
  }
}

/// 排序方式选择器，紧凑胶囊形态。
class _SortChip extends StatelessWidget {
  const _SortChip({required this.sort, required this.onSortSelected});

  final String sort;
  final ValueChanged<String> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      initialValue: sort,
      onSelected: onSortSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sort == 'size' ? Icons.straighten_rounded : Icons.sort_by_alpha_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              sort == 'size' ? l10n.sortBySize : l10n.sortByName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'name',
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_rounded, size: 18, color: sort == 'name' ? theme.colorScheme.primary : null),
              const SizedBox(width: 8),
              Text(l10n.sortByName),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'size',
          child: Row(
            children: [
              Icon(Icons.straighten_rounded, size: 18, color: sort == 'size' ? theme.colorScheme.primary : null),
              const SizedBox(width: 8),
              Text(l10n.sortBySize),
            ],
          ),
        ),
      ],
    );
  }
}
