import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_launcher.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../domain/entities/file_background_task.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../preferences/providers/preferences_providers.dart';
import '../../../transfers/presentation/providers/transfer_providers.dart';
import '../providers/file_page_actions.dart';
import '../providers/file_providers.dart';
import '../widgets/file_detail_sheet.dart';
import '../widgets/file_list_item.dart';
import '../widgets/file_type_helper.dart';
import '../widgets/files_header.dart';
import '../widgets/files_selection_bar.dart';

/// 文件管理页面。
///
/// 当前第二刀继续把“当前路径 / 排序方式”回归页面本地状态，
/// 再通过 family provider 按参数取数，减少全局状态依赖。
class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({
    super.key,
    this.directoryPickerMode = false,
    this.initialPath = _FilesPageState._rootPath,
  });

  /// 目录选择模式下只允许浏览和确认目录，不展示普通文件管理操作。
  final bool directoryPickerMode;

  /// 进入页面时默认展示的目录。
  final String initialPath;

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  static const String _rootPath = '/';
  static const String _defaultSort = 'type';

  Timer? _pollTimer;
  String? _lastFinishedDownloadId;
  Set<String> _lastBackgroundTaskIds = <String>{};

  /// 当前页面所在目录。
  String _currentPath = _rootPath;

  /// 当前页面文件排序方式。
  String _sort = _defaultSort;

  /// 当前页面已选择的文件路径集合。
  Set<String> _selectedPaths = <String>{};

  /// 是否处于多选模式。
  bool get _selectionMode => _selectedPaths.isNotEmpty;

  /// 当前文件列表查询条件。
  FileListQuery get _fileQuery => FileListQuery(path: _currentPath, sort: _sort);

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final currentServer = ref.read(activeServerProvider);
      final currentSession = ref.read(activeSessionProvider);
      if (currentServer == null || currentSession == null || _selectionMode) return;
      ref.invalidate(fileListProvider(_fileQuery));
    });

    ref.listenManual(latestFinishedDownloadProvider, (previous, next) {
      if (!mounted || next == null) return;
      if (_lastFinishedDownloadId == next.id) return;
      _lastFinishedDownloadId = next.id;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${next.title} 下载完成'),
          action: SnackBarAction(
            label: '打开',
            onPressed: () async {
              try {
                await FileLauncher.open(next.targetPath);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ErrorMapper.map(e).message)),
                );
              }
            },
          ),
        ),
      );
    });

    ref.listenManual(fileBackgroundTasksProvider, (previous, next) {
      if (!mounted) return;

      final tasks = next.valueOrNull ?? const <FileBackgroundTask>[];
      final currentIds = tasks.map((task) => task.taskId).toSet();
      final finishedIds = _lastBackgroundTaskIds.difference(currentIds);
      if (finishedIds.isEmpty) {
        _lastBackgroundTaskIds = currentIds;
        return;
      }

      final previousTasks = previous?.valueOrNull ?? const <FileBackgroundTask>[];
      final finishedTasks = previousTasks.where((task) => finishedIds.contains(task.taskId)).toList();
      final shouldRefresh = finishedTasks.any(_taskAffectsCurrentPath);

      _lastBackgroundTaskIds = currentIds;

      if (shouldRefresh) {
        _refreshCurrentPath();
      }

      if (finishedTasks.isNotEmpty) {
        final first = finishedTasks.first;
        final count = finishedTasks.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 1 ? '${first.displayName}等$count 个后台任务已完成' : '${first.displayName}任务已完成'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// 刷新当前目录文件列表。
  void _refreshCurrentPath() {
    ref.invalidate(fileListProvider(_fileQuery));
  }

  bool _taskAffectsCurrentPath(FileBackgroundTask task) {
    final taskPath = task.path.trim();
    if (taskPath.isEmpty) return true;
    if (_currentPath == _rootPath) return true;
    return taskPath == _currentPath || taskPath.startsWith('$_currentPath/');
  }

  /// 进入指定目录并清空多选状态。
  void _setCurrentPath(String path) {
    setState(() {
      _currentPath = path;
      _selectedPaths = <String>{};
    });
    _refreshCurrentPath();
  }

  /// 更新排序方式并刷新当前列表。
  void _setSort(String sort) {
    setState(() {
      _sort = sort;
    });
    _refreshCurrentPath();
  }

  /// 进入或切换多选状态。
  void _toggleSelection(FileItem item) {
    final actions = ref.read(filePageActionsProvider);
    setState(() {
      _selectedPaths = actions.toggleSelection(_selectedPaths, item);
    });
  }

  /// 清空当前页面的多选状态。
  void _clearSelection() {
    final actions = ref.read(filePageActionsProvider);
    setState(() {
      _selectedPaths = actions.clearSelection();
    });
  }

  /// 选择单个本地文件用于上传。
  Future<({String fileName, Uint8List bytes})?> _pickSingleFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    if (file.bytes == null) return null;
    return (fileName: file.name, bytes: file.bytes!);
  }

  /// 展示文件详情面板。
  void _showFileDetail(BuildContext context, FileItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FileDetailSheet(item: item),
    );
  }

  /// 展示重命名对话框。
  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref, FileItem item) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: item.name);
    String? errorText;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.rename),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: InputDecoration(labelText: l10n.newName)),
              if (errorText != null) ...[
                const SizedBox(height: 12),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: isSubmitting ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) {
                        setState(() => errorText = l10n.newName);
                        return;
                      }
                      setState(() {
                        isSubmitting = true;
                        errorText = null;
                      });
                      try {
                        await ref.read(fileRenameProvider)(item.path, newName);
                        _refreshCurrentPath();
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        setState(() {
                          errorText = ErrorMapper.map(e).message;
                          isSubmitting = false;
                        });
                      }
                    },
              child: Text(isSubmitting ? l10n.processing : l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 确认并删除单个文件。
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, FileItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteFile),
            content: Text('确定要删除“${item.name}”吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteConfirm)),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(fileDeleteProvider)(item.path);
      _refreshCurrentPath();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
      }
    }
  }

  /// 展示分享链接。
  Future<void> _showShareLink(BuildContext context, WidgetRef ref, FileItem item) async {
    final l10n = AppLocalizations.of(context);
    try {
      final link = await ref.read(fileShareProvider)(item.path);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.shareLink),
          content: SelectableText(link),
          actions: [
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
      }
    }
  }

  /// 确保本地下载目录已配置。
  Future<bool> _ensureDownloadDirectorySelected(BuildContext context, WidgetRef ref) async {
    final current = ref.read(downloadDirectoryProvider);
    if (current != null && current.isNotEmpty) return true;

    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected == null || selected.isEmpty) {
      return false;
    }

    await ref.read(saveDownloadDirectoryProvider)(selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载目录已设置为 $selected')),
      );
    }
    return true;
  }

  /// 展示单个文件的快捷操作菜单。
  void _showItemMenu(BuildContext context, WidgetRef ref, FileItem item) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (FileTypeHelper.isImage(item))
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('预览图片'),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).push('/image-preview', extra: {
                    'path': item.path,
                    'name': item.name,
                  });
                },
              ),
            if (FileTypeHelper.isTextPreviewable(item))
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(FileTypeHelper.isNfo(item) ? '预览 NFO' : '预览文本'),
                onTap: () {
                  Navigator.of(context).pop();
                  GoRouter.of(context).push('/text-preview', extra: {
                    'path': item.path,
                    'name': item.name,
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.detail),
              onTap: () {
                Navigator.of(context).pop();
                _showFileDetail(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: Text(l10n.rename),
              onTap: () {
                Navigator.of(context).pop();
                _showRenameDialog(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('下载'),
              onTap: () async {
                Navigator.of(context).pop();
                final ready = await _ensureDownloadDirectorySelected(context, ref);
                if (!ready) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('开始下载 ${item.name}')));
                }
                await ref.read(transferControllerProvider.notifier).enqueueDownload(
                      remotePath: item.path,
                      displayName: item.name,
                    );
              },
            ),
            if (FileTypeHelper.isImage(item) || FileTypeHelper.isVideo(item))
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('下载并打开'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final ready = await _ensureDownloadDirectorySelected(context, ref);
                  if (!ready) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('开始下载 ${item.name}，完成后可直接打开')),
                    );
                  }
                  await ref.read(transferControllerProvider.notifier).enqueueDownload(
                        remotePath: item.path,
                        displayName: item.name,
                      );
                },
              ),
            ListTile(
              leading: const Icon(Icons.link_rounded),
              title: Text(l10n.generateShareLink),
              onTap: () {
                Navigator.of(context).pop();
                _showShareLink(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text(l10n.deleteConfirm, style: const TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(context).pop();
                _confirmDelete(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(activeServerProvider);
    final currentSession = ref.watch(activeSessionProvider);

    if (currentServer == null || currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.filesTitle)),
        body: Center(child: Text(l10n.noSessionPleaseLogin)),
      );
    }

    final actions = ref.read(filePageActionsProvider);
    final filesAsync = ref.watch(fileListProvider(_fileQuery));
    final canGoUp = _currentPath != _rootPath;
    final activeTransferCount = ref.watch(activeTransferCountProvider);
    final backgroundTasksAsync = ref.watch(fileBackgroundTasksProvider);
    final backgroundTasks = backgroundTasksAsync.valueOrNull ?? const <FileBackgroundTask>[];
    final isDirectoryPickerMode = widget.directoryPickerMode;

    return PopScope(
      canPop: !canGoUp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (canGoUp) {
          _setCurrentPath(actions.parentPathOf(_currentPath));
        }
      },
      child: Scaffold(
        appBar: isDirectoryPickerMode
            ? AppBar(title: const Text('选择上传目录'))
            : _selectionMode
                ? FilesSelectionBar(
                    selectedCount: _selectedPaths.length,
                    onCancel: _clearSelection,
                    onDownload: () {
                      final currentFiles = filesAsync.valueOrNull ?? const <FileItem>[];
                      actions.downloadSelected(context, ref, currentFiles, _selectedPaths, _clearSelection);
                    },
                    onDelete: () => actions.deleteSelected(context, ref, _selectedPaths, _clearSelection),
                  )
                : AppBar(
                    title: Text(l10n.filesTitle),
                    actions: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            tooltip: '传输',
                            onPressed: () => GoRouter.of(context).push('/transfers'),
                            icon: AnimatedRotation(
                              turns: activeTransferCount > 0 ? 0.125 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(activeTransferCount > 0 ? Icons.sync_rounded : Icons.swap_horiz_rounded),
                            ),
                          ),
                          if (activeTransferCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Text(
                                  activeTransferCount > 99 ? '99+' : '$activeTransferCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
        body: Column(
          children: [
            if (!isDirectoryPickerMode && backgroundTasks.isNotEmpty)
              _BackgroundTaskBanner(
                tasks: backgroundTasks,
                onRefresh: () {
                  final matched = backgroundTasks.any(_taskAffectsCurrentPath);
                  if (matched) {
                    _refreshCurrentPath();
                  }
                },
              ),
            FilesHeader(
              path: _currentPath,
              sort: _sort,
              canGoUp: canGoUp,
              onRefresh: _refreshCurrentPath,
              onSortSelected: _setSort,
              onTapSegment: _setCurrentPath,
              onGoUp: () => _setCurrentPath(actions.parentPathOf(_currentPath)),
              onUpload: () => actions.showUploadDialog(context, ref, _currentPath, _pickSingleFile),
              onCreateFolder: () => actions.showCreateFolderDialog(context, ref, _currentPath),
              title: isDirectoryPickerMode ? '选择上传目录' : '文件管理',
              showActionMenu: !isDirectoryPickerMode,
            ),
            Expanded(
              child: filesAsync.when(
                data: (files) {
                  if (files.isEmpty) {
                    return Center(child: Text(l10n.folderIsEmpty));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = files[index];
                      final selected = _selectedPaths.contains(item.path);

                      return FileListItem(
                        item: item,
                        selected: selected,
                        selectionMode: _selectionMode,
                        onLongPress: isDirectoryPickerMode ? () {} : () => _toggleSelection(item),
                        onTap: () {
                          if (isDirectoryPickerMode) {
                            if (item.isDirectory) {
                              _setCurrentPath(item.path);
                            }
                            return;
                          }
                          if (_selectionMode) {
                            _toggleSelection(item);
                            return;
                          }
                          if (item.isDirectory) {
                            _setCurrentPath(item.path);
                            return;
                          }
                          if (FileTypeHelper.isTextPreviewable(item)) {
                            GoRouter.of(context).push('/text-preview', extra: {
                              'path': item.path,
                              'name': item.name,
                            });
                            return;
                          }
                          if (FileTypeHelper.isImage(item)) {
                            GoRouter.of(context).push('/image-preview', extra: {
                              'path': item.path,
                              'name': item.name,
                            });
                            return;
                          }
                          if (FileTypeHelper.isVideo(item)) {
                            GoRouter.of(context).push('/video-preview', extra: {
                              'baseUrl': ServerUrlHelper.buildBaseUrl(currentServer),
                              'path': item.path,
                              'name': item.name,
                              'synoToken': currentSession.synoToken,
                            });
                            return;
                          }
                          _showFileDetail(context, item);
                        },
                        onMore: isDirectoryPickerMode ? () {} : () => _showItemMenu(context, ref, item),
                      );
                    },
                  );
                },
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('加载文件失败：${ErrorMapper.map(error).message}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _refreshCurrentPath, child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isDirectoryPickerMode
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    onPressed: () => context.pop(_currentPath),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('选择当前目录：$_currentPath'),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _BackgroundTaskBanner extends StatelessWidget {
  const _BackgroundTaskBanner({
    required this.tasks,
    required this.onRefresh,
  });

  final List<FileBackgroundTask> tasks;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = tasks.first;
    final extraCount = tasks.length - 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sync_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extraCount > 0 ? '后台任务进行中（${tasks.length}）' : '后台任务进行中',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${first.displayName} · ${first.path.isEmpty ? '处理中' : first.path}${first.progress == null ? '' : ' · ${first.progress!.toStringAsFixed(0)}%'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }
}
