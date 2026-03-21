import 'package:flutter/material.dart';

import '../../../../domain/entities/file_item.dart';

class FileTypeHelper {
  static IconData iconFor(FileItem item) {
    if (item.isDirectory) return Icons.folder_rounded;

    final ext = extensionOf(item.name);
    switch (ext) {
      case 'yaml':
      case 'yml':
      case 'json':
      case 'toml':
      case 'ini':
      case 'conf':
      case 'env':
      case 'xml':
      case 'txt':
      case 'md':
      case 'log':
        return Icons.article_outlined;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return Icons.movie_outlined;
      case 'mp3':
      case 'flac':
      case 'wav':
      case 'm4a':
        return Icons.audio_file_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Color colorFor(BuildContext context, FileItem item) {
    final scheme = Theme.of(context).colorScheme;
    if (item.isDirectory) return scheme.primary;

    final ext = extensionOf(item.name);
    switch (ext) {
      case 'yaml':
      case 'yml':
      case 'json':
      case 'toml':
      case 'ini':
      case 'conf':
      case 'env':
      case 'xml':
      case 'txt':
      case 'md':
      case 'log':
        return Colors.teal;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      default:
        return scheme.secondary;
    }
  }

  static bool isTextEditable(FileItem item) {
    if (item.isDirectory) return false;
    const editable = {
      'txt', 'md', 'json', 'yaml', 'yml', 'toml', 'ini', 'conf', 'env', 'xml', 'log'
    };
    return editable.contains(extensionOf(item.name));
  }

  static String extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
