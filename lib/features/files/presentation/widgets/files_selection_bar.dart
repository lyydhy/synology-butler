import 'package:flutter/material.dart';

class FilesSelectionBar extends StatelessWidget implements PreferredSizeWidget {
  const FilesSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
    required this.onDownload,
    required this.onCopy,
    required this.onMove,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onDownload;
  final VoidCallback onCopy;
  final VoidCallback onMove;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: onCancel,
        icon: const Icon(Icons.close),
      ),
      title: Text('已选择 $selectedCount 项'),
      actions: [
        IconButton(
          onPressed: selectedCount == 0 ? null : onCopy,
          icon: const Icon(Icons.copy_outlined),
          tooltip: '复制到',
        ),
        IconButton(
          onPressed: selectedCount == 0 ? null : onMove,
          icon: const Icon(Icons.drive_file_move_outlined),
          tooltip: '移动到',
        ),
        IconButton(
          onPressed: selectedCount == 0 ? null : onDownload,
          icon: const Icon(Icons.download_rounded),
        ),
        IconButton(
          onPressed: selectedCount == 0 ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}
