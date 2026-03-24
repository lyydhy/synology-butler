import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/file_item.dart';
import '../providers/file_preview_providers.dart';
import 'file_type_helper.dart';

class FileListItem extends ConsumerWidget {
  const FileListItem({
    super.key,
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onMore,
  });

  final FileItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = FileTypeHelper.colorFor(context, item);
    final icon = FileTypeHelper.iconFor(item);
    final theme = Theme.of(context);

    return Material(
      color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.45) : theme.dividerColor.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              if (selectionMode) ...[
                Checkbox(value: selected, onChanged: (_) => onTap()),
                const SizedBox(width: 4),
              ],
              _LeadingVisual(item: item, color: color, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isDirectory ? item.path : _buildSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!selectionMode)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final size = FileSizeFormatter.format(item.size);
    return '${item.path} · $size';
  }
}

class _LeadingVisual extends ConsumerWidget {
  const _LeadingVisual({
    required this.item,
    required this.color,
    required this.icon,
  });

  final FileItem item;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (FileTypeHelper.isImage(item)) {
      final imageAsync = ref.watch(fileBytesProvider(item.path));
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageAsync.when(
          data: (bytes) => Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover),
          loading: () => Icon(Icons.image_outlined, color: color),
          error: (error, _) => Tooltip(
            message: ErrorMapper.map(error).message,
            child: Icon(Icons.broken_image_outlined, color: color),
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}
