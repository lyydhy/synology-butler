import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/api/synology_photos_api.dart';
import '../providers/photos_providers.dart';

/// 相册详情页
class AlbumDetailPage extends ConsumerWidget {
  final String albumId;

  const AlbumDetailPage({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: albumAsync.when(
          data: (album) => Text(album.name),
          loading: () => const Text('加载中...'),
          error: (_, __) => const Text('相册'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: albumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (album) => _AlbumContent(album: album, albumId: albumId),
      ),
    );
  }
}

/// 相册内容（封面照片 Grid + 描述）
class _AlbumContent extends ConsumerStatefulWidget {
  final FotoAlbum album;
  final String albumId;

  const _AlbumContent({required this.album, required this.albumId});

  @override
  ConsumerState<_AlbumContent> createState() => _AlbumContentState();
}

class _AlbumContentState extends ConsumerState<_AlbumContent> {
  final ScrollController _scrollController = ScrollController();
  bool _tabVisible = true;
  double _lastScrollY = 0;

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
    final y = _scrollController.offset;
    if (y > _lastScrollY && y > 80 && _tabVisible) {
      setState(() => _tabVisible = false);
    } else if (y < _lastScrollY && !_tabVisible) {
      setState(() => _tabVisible = true);
    }
    _lastScrollY = y;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(albumItemsProvider(widget.albumId));

    return Stack(
      children: [
        itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
          data: (items) => CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 相册描述
              if (widget.album.description != null && widget.album.description!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.album.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),

              // 照片 Grid
              if (items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('相册为空')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return _AlbumPhotoItem(item: item);
                      },
                      childCount: items.length,
                    ),
                  ),
                ),

              // 底部 padding
              SliverToBoxAdapter(
                child: SizedBox(height: _tabVisible ? 120 : 40),
              ),
            ],
          ),
        ),

        // 悬浮操作栏
        if (_tabVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActionButton(icon: Icons.share, label: '分享'),
                  _ActionButton(icon: Icons.download, label: '下载'),
                  _ActionButton(icon: Icons.delete_outline, label: '删除', color: Colors.red),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 相册内单张照片
class _AlbumPhotoItem extends ConsumerWidget {
  final FotoItem item;

  const _AlbumPhotoItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbAsync = ref.watch(photoThumbnailProvider(item.id));

    return GestureDetector(
      onTap: () {
        // TODO: navigate to photo detail
      },
      child: thumbAsync.when(
        loading: () => Container(color: Colors.grey[200]),
        error: (_, __) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 24),
        ),
        data: (bytes) => Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionButton({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? Colors.grey[700], size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }
}
