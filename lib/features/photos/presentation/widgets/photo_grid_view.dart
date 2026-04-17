import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/photos_providers.dart';
import '../../../../data/api/synology_photos_api.dart';

/// 按日期分组数据
class _DateGroup {
  final String label; // "今天"、"昨天"、"6月15日"
  final List<FotoItem> items;

  _DateGroup({required this.label, required this.items});
}

String _formatDateLabel(int timestamp) {
  final now = DateTime.now();
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  if (diff < 7) return '${diff}天前';
  return '${date.month}月${date.day}日';
}

List<_DateGroup> _groupByDate(List<FotoItem> items) {
  final Map<String, List<FotoItem>> map = {};
  for (final item in items) {
    if (item.createdTime == null) continue;
    final label = _formatDateLabel(item.createdTime!);
    map.putIfAbsent(label, () => []).add(item);
  }
  return map.entries.map((e) => _DateGroup(label: e.key, items: e.value)).toList();
}

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

        final groups = _groupByDate(items);
        // Collect all item IDs for detail navigation
        final allIds = items.map((e) => e.id).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(photoTimelineAllProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              for (final group in groups) ...[
                // 日期标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                // 日期内照片 Grid
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
                        final item = group.items[index];
                        final isSelected = selected.contains(item.id);

                        return _PhotoTile(
                          item: item,
                          isMultiSelect: selected.isNotEmpty,
                          isSelected: isSelected,
                          onTap: () {
                            if (selected.isNotEmpty) {
                              ref.read(photoMultiSelectProvider.notifier).toggle(item.id);
                            } else {
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
                      childCount: group.items.length,
                    ),
                  ),
                ),
              ],
              // 底部空白（给悬浮Tab留空间）
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
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
