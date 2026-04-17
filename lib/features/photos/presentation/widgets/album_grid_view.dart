import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/photos_providers.dart';
import '../../../../data/api/synology_photos_api.dart';

/// 相册 Grid（分页加载）
class AlbumGridView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const AlbumGridView({super.key, this.scrollController});

  @override
  ConsumerState<AlbumGridView> createState() => _AlbumGridViewState();
}

class _AlbumGridViewState extends ConsumerState<AlbumGridView> {
  late ScrollController _scrollController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_ownsController) _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(photoAlbumsAllProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(photoAlbumsAllProvider);

    return albumsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(photoAlbumsAllProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return const Center(child: Text('暂无相册'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(photoAlbumsAllProvider.notifier).refresh(),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return _AlbumCard(album: album);
            },
          ),
        );
      },
    );
  }
}

class _AlbumCard extends ConsumerWidget {
  final FotoAlbum album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = album.coverItemId != null
        ? ref.watch(photoThumbnailProvider(album.coverItemId!))
        : null;

    return GestureDetector(
      onTap: () => context.push('/photos/album/${album.id}?name=${Uri.encodeComponent(album.name)}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: coverAsync != null
                  ? coverAsync.when(
                      loading: () => Container(color: Colors.grey[200]),
                      error: (_, __) => _buildPlaceholder(),
                      data: (bytes) => Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${album.photoCount ?? 0} 张照片',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.photo_album, size: 40, color: Colors.grey),
    );
  }
}
