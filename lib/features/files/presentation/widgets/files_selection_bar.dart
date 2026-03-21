import 'package:flutter/material.dart';

class FilesSelectionBar extends StatelessWidget implements PreferredSizeWidget {
  const FilesSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

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
          onPressed: selectedCount == 0 ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}
