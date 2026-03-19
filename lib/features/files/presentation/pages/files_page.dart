import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../domain/entities/file_item.dart';
import '../providers/file_providers.dart';
import '../widgets/file_detail_sheet.dart';
import '../widgets/path_breadcrumb.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key});

  String parentPathOf(String path) {
    if (path == '/' || path.isEmpty) return '/';
    final normalized = path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
    final index = normalized.lastIndexOf('/');
    if (index <= 0) return '/';
    return normalized.substring(0, index);
  }

  Future<void> _showCreateFolderDialog(BuildContext context, WidgetRef ref, String currentPath) async {
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

  Future<void> _showUploadDialog(BuildContext context, WidgetRef ref, String currentPath) async {
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
                  final result = await FilePicker.platform.pickFiles(withData: true);
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      fileName = result.files.single.name;
                      fileBytes = result.files.single.bytes;
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
                        await ref.read(fileUploadProvider)(currentPath, fileName!, fileBytes!);
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

  void _showFileDetail(BuildContext context, FileItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FileDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(currentServerProvider);
    final currentSession = ref.watch(currentSessionProvider);

    if (currentServer == null || currentSession == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.filesTitle)), body: Center(child: Text(l10n.noSessionPleaseLogin)));
    }

    final path = ref.watch(currentPathProvider);
    final sort = ref.watch(fileSortProvider);
    final filesAsync = ref.watch(fileListProvider);
    final canGoUp = path != '/';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.filesTitle)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${l10n.currentPath}：$path')),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      initialValue: sort,
                      onSelected: (value) => ref.read(fileSortProvider.notifier).state = value,
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'name', child: Text(l10n.sortByName)),
                        PopupMenuItem(value: 'size', child: Text(l10n.sortBySize)),
                      ],
                    ),
                    IconButton(onPressed: () => ref.invalidate(fileListProvider), icon: const Icon(Icons.refresh)),
                  ],
                ),
                const SizedBox(height: 8),
                PathBreadcrumb(
                  path: path,
                  onTapSegment: (selectedPath) {
                    ref.read(currentPathProvider.notifier).state = selectedPath;
                    ref.invalidate(fileListProvider);
                  },
                ),
                if (canGoUp)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        ref.read(currentPathProvider.notifier).state = parentPathOf(path);
                        ref.invalidate(fileListProvider);
                      },
                      icon: const Icon(Icons.arrow_upward),
                      label: Text(l10n.goParent),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filesAsync.when(
              data: (files) {
                if (files.isEmpty) {
                  return Center(child: Text(l10n.folderIsEmpty));
                }
                return ListView.separated(
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = files[index];
                    return ListTile(
                      leading: Icon(item.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined),
                      title: Text(item.name),
                      subtitle: Text(item.path),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenameDialog(context, ref, item);
                          } else if (value == 'delete') {
                            _confirmDelete(context, ref, item);
                          } else if (value == 'share') {
                            _showShareLink(context, ref, item);
                          } else if (value == 'detail') {
                            _showFileDetail(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'detail', child: Text(l10n.detail)),
                          PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                          PopupMenuItem(value: 'share', child: Text(l10n.generateShareLink)),
                          PopupMenuItem(value: 'delete', child: Text(l10n.deleteConfirm)),
                        ],
                        child: item.isDirectory
                            ? const Icon(Icons.more_vert)
                            : Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(FileSizeFormatter.format(item.size)),
                              ),
                      ),
                      onTap: item.isDirectory
                          ? () {
                              ref.read(currentPathProvider.notifier).state = item.path;
                              ref.invalidate(fileListProvider);
                            }
                          : () => _showFileDetail(context, item),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'uploadFab',
            onPressed: () => _showUploadDialog(context, ref, path),
            child: const Icon(Icons.upload_file_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'createFolderFab',
            onPressed: () => _showCreateFolderDialog(context, ref, path),
            child: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
    );
  }
}
