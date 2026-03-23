import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transfers/presentation/providers/transfer_providers.dart';
import 'file_providers.dart';
import 'file_selection_providers.dart';

class FilePageActions {
  const FilePageActions();

  String parentPathOf(String path) {
    if (path == '/' || path.isEmpty) return '/';
    final normalized = path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '/';
    return normalized.substring(0, index);
  }

  void toggleSelection(WidgetRef ref, FileItem item) {
    final current = {...ref.read(selectedFilePathsProvider)};
    if (current.contains(item.path)) {
      current.remove(item.path);
    } else {
      current.add(item.path);
    }
    ref.read(selectedFilePathsProvider.notifier).state = current;
  }

  void clearSelection(WidgetRef ref) {
    ref.read(selectedFilePathsProvider.notifier).state = <String>{};
  }

  Future<void> downloadSelected(BuildContext context, WidgetRef ref, List<FileItem> files) async {
    final selectedPaths = ref.read(selectedFilePathsProvider);
    final selectedItems = files.where((item) => selectedPaths.contains(item.path) && !item.isDirectory).toList();
    if (selectedItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请至少选择一个文件进行下载')));
      }
      return;
    }

    await ref.read(transferControllerProvider.notifier).enqueueBatchDownload([
      for (final item in selectedItems) (item.path, item.name),
    ]);

    clearSelection(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已加入 ${selectedItems.length} 个下载任务')));
    }
  }

  Future<void> deleteSelected(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final paths = ref.read(selectedFilePathsProvider).toList();
    if (paths.isEmpty) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('批量删除'),
            content: Text('确定要删除选中的 ${paths.length} 项吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteConfirm)),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(fileBatchDeleteProvider)(paths);
      clearSelection(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已删除 ${paths.length} 项')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
      }
    }
  }

  Future<void> showCreateFolderDialog(BuildContext context, WidgetRef ref, String currentPath) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.createFolder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: InputDecoration(labelText: l10n.folderName)),
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
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        setState(() => errorText = l10n.folderName);
                        return;
                      }
                      setState(() {
                        isSubmitting = true;
                        errorText = null;
                      });
                      try {
                        await ref.read(fileActionProvider)(currentPath, name);
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

  Future<void> showUploadDialog(
    BuildContext context,
    WidgetRef ref,
    String currentPath,
    Future<({String fileName, Uint8List bytes})?> Function() picker,
  ) async {
    final l10n = AppLocalizations.of(context);
    String? fileName;
    Uint8List? fileBytes;
    String? errorText;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.uploadFile),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.targetFolder}：$currentPath'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await picker();
                  if (result != null) {
                    setState(() {
                      fileName = result.fileName;
                      fileBytes = result.bytes;
                      errorText = null;
                    });
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(l10n.chooseFile),
              ),
              const SizedBox(height: 8),
              Text(fileName ?? l10n.noFileSelected),
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
                      if (fileName == null || fileBytes == null) {
                        setState(() => errorText = l10n.noFileSelected);
                        return;
                      }
                      setState(() {
                        isSubmitting = true;
                        errorText = null;
                      });
                      try {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入上传任务')));
                        }
                        await ref.read(transferControllerProvider.notifier).enqueueUpload(
                              parentPath: currentPath,
                              fileName: fileName!,
                              bytes: fileBytes!,
                            );
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        setState(() {
                          errorText = ErrorMapper.map(e).message;
                          isSubmitting = false;
                        });
                      }
                    },
              child: Text(isSubmitting ? l10n.uploading : l10n.startUpload),
            ),
          ],
        ),
      ),
    );
  }
}

final filePageActionsProvider = Provider((ref) => const FilePageActions());
