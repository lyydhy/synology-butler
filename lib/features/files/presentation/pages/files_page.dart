import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_launcher.dart';
import '../../../../core/utils/server_url_helper.dart';
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
/// 当前第一刀先把“已选中文件集合”回归页面本地状态；
/// 路径与排序仍保持现有 provider 方案，避免一次改动过大。
class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  Timer? _pollTimer;
  String? _lastFinishedDownloadId;

  /// 当前页面已选择的文件路径集合。
  Set<String> _selectedPaths = <String>{};

  /// 是否处于多选模式。
  bool get _selectionMode => _selectedPaths.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final currentServer = ref.read(activeServerProvider);
      final currentSession = ref.read(activeSessionProvider);
      if (currentServer == null || currentSession == null || _selectionMode) return;
      ref.invalidate(fileListProvider);
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
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
                        ref.invalidate(fileListProvider);
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
      ref.invalidate(fileListProvider);
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
    final path = ref.watch(currentPathProvider);
    final sort = ref.watch(fileSortProvider);
    final filesAsync = ref.watch(fileListProvider);
    final canGoUp = path != '/';
    final activeTransferCount = ref.watch(activeTransferCountProvider);

    return PopScope(
      canPop: !canGoUp,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (canGoUp) {
          final parentPath = actions.parentPathOf(path);
          ref.read(currentPathProvider.notifier).state = parentPath;
          ref.invalidate(fileListProvider);
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: _selectionMode
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
            FilesHeader(
              path: path,
              sort: sort,
              canGoUp: canGoUp,
              onRefresh: () => ref.invalidate(fileListProvider),
              onSortSelected: (value) => ref.read(fileSortProvider.notifier).state = value,
              onTapSegment: (selectedPath) {
                ref.read(currentPathProvider.notifier).state = selectedPath;
                _clearSelection();
                ref.invalidate(fileListProvider);
              },
              onGoUp: () {
                ref.read(currentPathProvider.notifier).state = actions.parentPathOf(path);
                _clearSelection();
                ref.invalidate(fileListProvider);
              },
              onUpload: () => actions.showUploadDialog(context, ref, path, _pickSingleFile),
              onCreateFolder: () => actions.showCreateFolderDialog(context, ref, path),
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
                        onLongPress: () => _toggleSelection(item),
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(item);
                            return;
                          }
                          if (item.isDirectory) {
                            ref.read(currentPathProvider.notifier).state = item.path;
                            _clearSelection();
                            ref.invalidate(fileListProvider);
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
                        onMore: () => _showItemMenu(context, ref, item),
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
                        FilledButton(onPressed: () => ref.invalidate(fileListProvider), child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
