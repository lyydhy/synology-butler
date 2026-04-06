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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              const SizedBox(width: 10),
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
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!selectionMode)
                IconButton(
                  onPressed: onMore,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.more_horiz, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final modified = item.modifiedAt;
    final timeText = modified == null ? '--' : _formatModifiedTime(modified);

    if (item.isDirectory) {
      return timeText;
    }

    final size = FileSizeFormatter.format(item.size);
    return '$timeText · $size';
  }

  String _formatModifiedTime(DateTime modified) {
    final local = modified.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$mi';
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
      // 使用 select 避免不必要的重建
      final imageAsync = ref.watch(
        fileBytesProvider(item.path).select((value) => value),
      );
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageAsync.when(
          data: (bytes) {
            // bytes 已经是 Uint8List，不需要再转换
            return Image.memory(bytes, fit: BoxFit.cover);
          },
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
