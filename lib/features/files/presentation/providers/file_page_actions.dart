import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../transfers/presentation/providers/transfer_providers.dart';
import 'file_providers.dart';

/// 文件页交互动作集合。
///
/// 这里保留与仓库、传输队列等 provider 的协作，
/// 但不再直接持有“已选中文件”这类页面局部状态。
class FilePageActions {
  const FilePageActions();

  /// 计算当前路径的父级目录。
  String parentPathOf(String path) {
    if (path == '/' || path.isEmpty) return '/';
    final normalized = path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '/';
    return normalized.substring(0, index);
  }

  /// 切换某个文件项的选中状态。
  Set<String> toggleSelection(Set<String> selectedPaths, FileItem item) {
    final next = {...selectedPaths};
    if (next.contains(item.path)) {
      next.remove(item.path);
    } else {
      next.add(item.path);
    }
    return next;
  }

  /// 清空当前页面选择集。
  Set<String> clearSelection() => <String>{};

  /// 将当前选中的文件加入下载队列。
  Future<void> downloadSelected(
    BuildContext context,
    WidgetRef ref,
    List<FileItem> files,
    Set<String> selectedPaths,
    VoidCallback onSelectionCleared,
  ) async {
    
    final selectedItems = files.where((item) => selectedPaths.contains(item.path) && !item.isDirectory).toList();
    if (selectedItems.isEmpty) {
      if (context.mounted) {
        Toast.warning(l10n.selectOneFile);
      }
      return;
    }

    await ref.read(transferControllerProvider.notifier).enqueueBatchDownload([
      for (final item in selectedItems) (item.path, item.name),
    ]);

    onSelectionCleared();
    if (context.mounted) {
      Toast.show(l10n.addedDownloadTasks(selectedItems.length));
    }
  }

  /// 批量删除当前选中的文件。
  Future<void> deleteSelected(
    BuildContext context,
    WidgetRef ref,
    Set<String> selectedPaths,
    VoidCallback onSelectionCleared,
  ) async {
    
    final paths = selectedPaths.toList();
    if (paths.isEmpty) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.batchDelete),
            content: Text(l10n.confirmBatchDelete(paths.length)),
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
      onSelectionCleared();
      if (context.mounted) {
        Toast.success(l10n.deletedCount(paths.length));
      }
    } catch (e) {
      if (context.mounted) {
        Toast.error(ErrorMapper.map(e).message);
      }
    }
  }

  /// 展示新建文件夹对话框。
  Future<void> showCreateFolderDialog(BuildContext context, WidgetRef ref, String currentPath) async {
    
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

  /// 展示上传文件对话框。
  Future<void> showUploadDialog(
    BuildContext context,
    WidgetRef ref,
    String currentPath,
    Future<({String fileName, Uint8List bytes})?> Function() picker,
  ) async {
    
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
                          Toast.show(l10n.uploadTaskAdded);
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
