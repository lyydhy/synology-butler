import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/photos_providers.dart';
import '../../../../data/api/synology_photos_api.dart';

/// 照片时间线 Grid（分页加载 + 多选）
class PhotoGridView extends ConsumerStatefulWidget {
  const PhotoGridView({super.key});

  @override
  ConsumerState<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends ConsumerState<PhotoGridView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(photoTimelineAllProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(photoTimelineAllProvider);
    final selected = ref.watch(photoMultiSelectProvider);

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(photoTimelineAllProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('暂无照片'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(photoTimelineAllProvider.notifier).refresh(),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selected.contains(item.id);

              return _PhotoTile(
                item: item,
                isMultiSelect: selected.isNotEmpty,
                isSelected: isSelected,
                onTap: () {
                  if (selected.isNotEmpty) {
                    ref.read(photoMultiSelectProvider.notifier).toggle(item.id);
                  } else {
                    final allIds = items.map((e) => e.id).toList();
                    context.push('/photos/detail', extra: {
                      'photoId': item.id,
                      'allPhotoIds': allIds,
                    });
                  }
                },
                onLongPress: () {
                  ref.read(photoMultiSelectProvider.notifier).toggle(item.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PhotoTile extends ConsumerWidget {
  final FotoItem item;
  final bool isMultiSelect;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoTile({
    required this.item,
    required this.isMultiSelect,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsync = ref.watch(photoThumbnailProvider(item.id));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumbnailAsync.when(
            loading: () => Container(color: Colors.grey[200]),
            error: (_, __) => Container(color: Colors.grey[200]),
            data: (bytes) => Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            ),
          ),

          // 多选 checkbox
          if (isMultiSelect)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),

          // 视频标识
          if (item.isVideo)
            Positioned(
              right: isMultiSelect ? 30 : 4,
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
