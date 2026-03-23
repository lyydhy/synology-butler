import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import 'file_preview_providers.dart';

final saveImageToGalleryProvider = Provider<Future<void> Function(String path, String title)>((ref) {
  return (path, title) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      throw Exception('没有相册权限');
    }

    final bytes = await ref.read(fileBytesProvider(path).future);
    await PhotoManager.editor.saveImage(
      Uint8List.fromList(bytes),
      title: title,
      filename: title,
    );
  };
});
