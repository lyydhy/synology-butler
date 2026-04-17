import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/photos_providers.dart';
import '../../../../data/api/synology_photos_api.dart';

/// 照片时间线 Grid View
class PhotoGridView extends ConsumerWidget {
  const PhotoGridView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(photoTimelineProvider(0));

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('加载失败: $e')),
      data: (response) {
        if (response.items.isEmpty) {
          return const Center(child: Text('暂无照片'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: response.items.length,
          itemBuilder: (context, index) {
            final item = response.items[index];
            return _PhotoTile(item: item);
          },
        );
      },
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  final FotoItem item;

  const _PhotoTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(photoThumbnailProvider(item.id));

    return GestureDetector(
      onTap: () => context.push('/photos/detail/${item.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 缩略图
          thumbnailAsync.when(
            loading: () => Container(color: Colors.grey[200]),
            error: (_, __) => Container(color: Colors.grey[200]),
            data: (bytes) => Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            ),
          ),

          // 视频标识
          if (item.isVideo)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
