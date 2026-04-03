import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/file_size_formatter.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../domain/entities/file_item.dart';
import 'file_type_helper.dart';

class FileDetailSheet extends StatelessWidget {
  const FileDetailSheet({
    super.key,
    required this.item,
  });

  final FileItem item;

  @override
  Widget build(BuildContext context) {
    

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.route_outlined),
              title: Text(l10n.filePath),
              subtitle: Text(item.path),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.isDirectory ? Icons.folder_outlined : Icons.insert_drive_file_outlined),
              title: Text(l10n.fileType),
              subtitle: Text(item.isDirectory ? l10n.folder : l10n.file),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.data_object_outlined),
              title: Text(l10n.fileSize),
              subtitle: Text(item.isDirectory ? '-' : FileSizeFormatter.format(item.size)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (FileTypeHelper.isImage(item))
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/image-preview', extra: {
                        'path': item.path,
                        'name': item.name,
                      });
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('预览图片'),
                  ),
                if (FileTypeHelper.isVideo(item))
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.movie_outlined),
                    label: const Text('视频预览请从列表打开'),
                  ),
                if (FileTypeHelper.isTextPreviewable(item))
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/text-preview', extra: {
                        'path': item.path,
                        'name': item.name,
                      });
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(FileTypeHelper.isNfo(item) ? '预览 NFO' : '预览文本'),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: item.path));
                    if (context.mounted) {
                      Toast.show('路径已复制');
                    }
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('复制路径'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
