import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/server_url_helper.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/file_background_task.dart';
import '../../../../domain/entities/file_item.dart';
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
/// 当前第二刀继续把"当前路径 / 排序方式"回归页面本地状态,
/// 再通过 family provider 按参数取数,减少全局状态依赖。
class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({
    super.key,
    this.directoryPickerMode = false,
    this.initialPath = _FilesPageState._rootPath,
  });

  /// 目录选择模式下只允许浏览和确认目录,不展示普通文件管理操作。
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
  ProviderSubscription<AsyncValue<List<FileBackgroundTask>>>? _backgroundTaskListener;
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
      final connection = ref.read(currentConnectionProvider);
      if (!connection.hasSession || _selectionMode) return;
      ref.invalidate(fileListProvider(_fileQuery));
    });

    _backgroundTaskListener = ref.listenManual(fileBackgroundTasksProvider, (previous, next) {
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
      final notifyTasks = finishedTasks.where((task) => !_isDownloadBackgroundTask(task)).toList();

      _lastBackgroundTaskIds = currentIds;

      if (shouldRefresh) {
        _refreshCurrentPath();
      }

      if (notifyTasks.isNotEmpty) {
        final first = notifyTasks.first;
        final count = notifyTasks.length;
        Toast.show(count > 1 ? l10n.taskCompleteMultiple(first.displayName, count) : l10n.taskComplete(first.displayName));
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _backgroundTaskListener?.close();
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

  bool _isDownloadBackgroundTask(FileBackgroundTask task) {
    return task.type.toLowerCase() == 'download';
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

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteFile),
            content: Text(l10n.confirmDeleteName(item.name)),
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
        Toast.success(l10n.deleteSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        Toast.error(ErrorMapper.map(e).message);
      }
    }
  }

  /// 确保本地下载目录已配置。
  Future<bool> _ensureDownloadDirectorySelected(BuildContext context, WidgetRef ref) async {
    final current = ref.read(downloadDirectoryProvider).valueOrNull;
    if (current != null && current.isNotEmpty) return true;

    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected == null || selected.isEmpty) {
      return false;
    }

    await ref.read(downloadDirectoryProvider.notifier).save(selected);
    if (context.mounted) {
      Toast.show(l10n.downloadDirSetTo(selected));
    }
    return true;
  }

  /// 展示单个文件的快捷操作菜单。
  void _showItemMenu(BuildContext context, WidgetRef ref, FileItem item) {

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
                title: Text(l10n.previewImage),
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
                title: Text(FileTypeHelper.isNfo(item) ? l10n.previewNfo : l10n.previewText),
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
              title: Text(l10n.download),
              onTap: () async {
                Navigator.of(context).pop();
                final ready = await _ensureDownloadDirectorySelected(context, ref);
                if (!ready) return;
                if (context.mounted) {
                  Toast.show(l10n.startDownloadingName(item.name));
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
                title: Text(l10n.downloadAndOpen),
                onTap: () async {
                  Navigator.of(context).pop();
                  final ready = await _ensureDownloadDirectorySelected(context, ref);
                  if (!ready) return;
                  if (context.mounted) {
                    Toast.show(l10n.downloadCompleteOpen(item.name));
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
                context.push('/share-link', extra: {'path': item.path});
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

    final connection = ref.watch(currentConnectionProvider);
    final currentServer = connection.server;
    final currentSession = connection.session;

    if (currentServer == null || currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.filesTitle)),
        body: Center(child: Text(l10n.noSessionPleaseLogin)),
      );
    }

    final actions = ref.read(filePageActionsProvider);
    final filesAsync = ref.watch(fileListProvider(_fileQuery));
    final canGoUp = _currentPath != _rootPath;
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
            ? AppBar(title: Text(l10n.selectUploadDir))
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
                    actions: const [],
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
              onCreateFolder: () => actions.showCreateFolderDialog(context, ref, _currentPath),
              title: isDirectoryPickerMode ? l10n.selectUploadDir : l10n.filesTitle,
              showActionMenu: !isDirectoryPickerMode,
            ),
            Expanded(
              child: filesAsync.when(
                data: (files) {
                  if (files.isEmpty) {
                    return Center(child: Text(l10n.folderIsEmpty));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
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
                              'sid': currentSession.sid,
                              'cookieHeader': currentSession.cookieHeader,
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
                        Text(l10n.loadFilesFailed(ErrorMapper.map(error).message), style: const TextStyle(color: Colors.red)),
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
                    label: Text(l10n.selectCurrentDir(_currentPath)),
                  ),
                ),
              )
            : null,
        floatingActionButton: isDirectoryPickerMode
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'fab_upload',
                    onPressed: () => actions.showUploadDialog(context, ref, _currentPath, _pickSingleFile),
                    tooltip: l10n.uploadFile,
                    child: const Icon(Icons.upload_rounded),
                  ),
                ],
              ),
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
                  extraCount > 0 ? l10n.backgroundTaskRunningCount(tasks.length) : l10n.backgroundTaskRunning,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${first.displayName} · ${first.path.isEmpty ? l10n.processingLabel : first.path}${first.progress == null ? '' : ' · ${first.progress!.toStringAsFixed(0)}%'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: Text(l10n.refresh),
          ),
        ],
      ),
    );
  }
}
