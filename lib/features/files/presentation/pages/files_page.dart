import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/file_page_actions.dart';
import '../providers/file_providers.dart';
import '../providers/file_selection_providers.dart';
import '../widgets/file_detail_sheet.dart';
import '../widgets/file_list_item.dart';
import '../widgets/files_header.dart';
import '../widgets/files_selection_bar.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  Future<({String fileName, Uint8List bytes})?> _pickSingleFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.bytes == null) return null;
    return (fileName: file.name, bytes: file.bytes!);
  }

  void _showFileDetail(BuildContext context, FileItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FileDetailSheet(item: item),
    );
  }

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
      }
    }
  }

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

  void _showItemMenu(BuildContext context, WidgetRef ref, FileItem item) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(currentServerProvider);
    final currentSession = ref.watch(currentSessionProvider);

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
    final selectedPaths = ref.watch(selectedFilePathsProvider);
    final selectionMode = ref.watch(fileSelectionModeProvider);

    return Scaffold(
      appBar: selectionMode
          ? FilesSelectionBar(
              selectedCount: selectedPaths.length,
              onCancel: () => actions.clearSelection(ref),
              onDelete: () => actions.deleteSelected(context, ref),
            )
          : AppBar(title: Text(l10n.filesTitle)),
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
              actions.clearSelection(ref);
              ref.invalidate(fileListProvider);
            },
            onGoUp: () {
              ref.read(currentPathProvider.notifier).state = actions.parentPathOf(path);
              actions.clearSelection(ref);
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
                    final selected = selectedPaths.contains(item.path);

                    return FileListItem(
                      item: item,
                      selected: selected,
                      selectionMode: selectionMode,
                      onLongPress: () => actions.toggleSelection(ref, item),
                      onTap: () {
                        if (selectionMode) {
                          actions.toggleSelection(ref, item);
                          return;
                        }

                        if (item.isDirectory) {
                          ref.read(currentPathProvider.notifier).state = item.path;
                          actions.clearSelection(ref);
                          ref.invalidate(fileListProvider);
                        } else {
                          _showFileDetail(context, item);
                        }
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
    );
  }
}
