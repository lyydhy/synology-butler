import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/api/synology_photos_api.dart';
import '../providers/photos_providers.dart';

/// 照片搜索页
class PhotosSearchPage extends ConsumerStatefulWidget {
  const PhotosSearchPage({super.key});

  @override
  ConsumerState<PhotosSearchPage> createState() => _PhotosSearchPageState();
}

class _PhotosSearchPageState extends ConsumerState<PhotosSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(photoSearchResultsProvider(_query));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: '搜索照片...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (val) => setState(() => _query = val),
        ),
        actions: [
          if (_query.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Text('取消', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _query.isEmpty
          ? _buildEmptyState()
          : results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('搜索失败: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('未找到"$_query"相关照片', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(2),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SearchResultTile(item: item);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('输入关键词搜索照片', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  final FotoItem item;

  const _SearchResultTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbAsync = ref.watch(photoThumbnailProvider(item.id));

    return GestureDetector(
      onTap: () {
        context.push('/photos/detail', extra: {'photoId': item.id, 'allPhotoIds': [item.id]});
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumbAsync.when(
            loading: () => Container(color: Colors.grey[200]),
            error: (_, __) => Container(color: Colors.grey[200]),
            data: (bytes) => Image.memory(bytes, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
          ),
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
