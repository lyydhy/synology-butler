import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../domain/entities/file_item.dart';
import '../providers/file_providers.dart';

/// 独立的目录选择 BottomSheet，数据隔离于主文件页。
class DirectoryPickerSheet extends ConsumerStatefulWidget {
  const DirectoryPickerSheet({
    super.key,
    required this.initialPath,
    required this.purpose,
  });

  final String initialPath;
  final String purpose; // 'upload' | 'copy' | 'move'

  @override
  ConsumerState<DirectoryPickerSheet> createState() => _DirectoryPickerSheetState();
}

class _DirectoryPickerSheetState extends ConsumerState<DirectoryPickerSheet> {
  late String _currentPath;
  late Future<List<FileItem>> _directoriesFuture;

  @override
  void initState() {
    super.initState();
    // 始终从根目录开始，不带入当前目录
    _currentPath = '/';
    _loadDirectories();
  }

  void _loadDirectories() {
    _directoriesFuture = ref.read(fileRepositoryProvider).listFiles(path: _currentPath);
  }

  String get _title {
    switch (widget.purpose) {
      case 'upload':
        return l10n.selectUploadDir;
      case 'copy':
        return l10n.selectTargetDir;
      case 'move':
        return l10n.selectTargetDir;
      default:
        return l10n.selectTargetDir;
    }
  }

  bool get _canGoUp => _currentPath != '/';

  String _parentPath(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/';
    segments.removeLast();
    return '/${segments.join('/')}';
  }

  void _navigateTo(String path) {
    setState(() {
      _currentPath = path;
      _loadDirectories();
    });
  }

  void _goUp() {
    if (_canGoUp) {
      _navigateTo(_parentPath(_currentPath));
    }
  }

  void _confirm(String path) {
    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.8;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 拖动条
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                ),
                Expanded(
                  child: Text(
                    _title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _confirm(_currentPath),
                  child: Text(l10n.confirm),
                ),
              ],
            ),
          ),
          // 路径 + 返回上级
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                IconButton(
                  onPressed: _canGoUp ? _goUp : null,
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    color: _canGoUp ? theme.colorScheme.primary : theme.colorScheme.outline,
                  ),
                  tooltip: l10n.goUp,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _currentPath,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _loadDirectories,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: l10n.refresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 目录列表
          Expanded(
            child: FutureBuilder<List<FileItem>>(
              future: _directoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          l10n.loadFilesFailed(snapshot.error.toString()),
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: _loadDirectories,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }

                final directories = snapshot.data?.where((f) => f.isDirectory).toList() ?? [];

                if (directories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 56,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.folderIsEmpty,
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: directories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final dir = directories[index];
                    return _DirectoryTile(
                      name: dir.name,
                      onTap: () => _navigateTo(dir.path),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectoryTile extends StatelessWidget {
  const _DirectoryTile({
    required this.name,
    required this.onTap,
  });

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.folder_rounded,
          color: theme.colorScheme.onPrimaryContainer,
          size: 22,
        ),
      ),
      title: Text(
        name,
        style: theme.textTheme.bodyLarge,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
