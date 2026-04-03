import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/toast.dart';
import '../providers/file_preview_providers.dart';
import '../providers/media_save_providers.dart';

class ImagePreviewPage extends ConsumerWidget {
  const ImagePreviewPage({
    super.key,
    required this.path,
    required this.name,
  });

  final String path;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(fileBytesProvider(path));

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: '保存到相册',
            onPressed: () async {
              try {
                await ref.read(saveImageToGalleryProvider)(path, name);
                if (context.mounted) {
                  Toast.success('已保存到相册');
                }
              } catch (e) {
                if (context.mounted) {
                  Toast.error(ErrorMapper.map(e).message);
                }
              }
            },
            icon: const Icon(Icons.save_alt_rounded),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: imageAsync.when(
        data: (bytes) => Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain),
          ),
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('正在加载图片...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              ErrorMapper.map(error).message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
