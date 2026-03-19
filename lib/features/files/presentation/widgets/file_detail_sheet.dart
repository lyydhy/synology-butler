import 'package:flutter/material.dart';

import '../../../../core/utils/file_size_formatter.dart';
import '../../../../domain/entities/file_item.dart';
import '../../../../l10n/app_localizations.dart';

class FileDetailSheet extends StatelessWidget {
  const FileDetailSheet({
    super.key,
    required this.item,
  });

  final FileItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
