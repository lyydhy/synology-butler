import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/photos_providers.dart';
import '../widgets/photo_grid_view.dart';
import '../widgets/album_grid_view.dart';

class PhotosTabPage extends ConsumerStatefulWidget {
  const PhotosTabPage({super.key});

  @override
  ConsumerState<PhotosTabPage> createState() => _PhotosTabPageState();
}

class _PhotosTabPageState extends ConsumerState<PhotosTabPage> {
  int _currentTab = 0; // 0=照片, 1=图集
  double _lastScrollY = 0;
  bool _tabVisible = true;

  void _switchSpace(PhotoSpace space) {
    ref.invalidate(photoTimelineAllProvider);
    ref.invalidate(photoAlbumsAllProvider);
    ref.read(photoSpaceProvider.notifier).state = space;
  }

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(photoSpaceProvider);
    final selected = ref.watch(photoMultiSelectProvider);
    final allIds = _currentTab == 0
        ? (ref.watch(photoTimelineAllProvider).valueOrNull?.map((e) => e.id).toList() ?? [])
        : (ref.watch(photoAlbumsAllProvider).valueOrNull?.map((e) => e.id).toList() ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: selected.isNotEmpty
            ? Text('已选择 ${selected.length} 项')
            : Text(space == PhotoSpace.personal ? '群晖照片' : '共享空间'),
        leading: selected.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(photoMultiSelectProvider.notifier).clear(),
              )
            : null,
        actions: [
          if (selected.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/photos/search'),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ] else ...[
            IconButton(
              icon: Icon(allIds.isNotEmpty && selected.length == allIds.length
                  ? Icons.deselect
                  : Icons.select_all),
              tooltip: allIds.isNotEmpty && selected.length == allIds.length ? '取消全选' : '全选',
              onPressed: allIds.isEmpty
                  ? null
                  : () {
                      if (selected.length == allIds.length) {
                        ref.read(photoMultiSelectProvider.notifier).clear();
                      } else {
                        ref.read(photoMultiSelectProvider.notifier).selectAll(allIds);
                      }
                    },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Space Switcher（多选时不显示）
          if (selected.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SpaceTab(
                        label: '个人空间',
                        isActive: space == PhotoSpace.personal,
                        onTap: () => _switchSpace(PhotoSpace.personal),
                      ),
                    ),
                    Expanded(
                      child: _SpaceTab(
                        label: '共享空间',
                        isActive: space == PhotoSpace.shared,
                        onTap: () => _switchSpace(PhotoSpace.shared),
                      ),
                    ),
                  ],
                ),
              ),
            ),


          // Content
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final y = notification.metrics.pixels;
                  if (y > _lastScrollY && y > 80 && _tabVisible) {
                    setState(() => _tabVisible = false);
                  } else if (y < _lastScrollY && !_tabVisible) {
                    setState(() => _tabVisible = true);
                  }
                  _lastScrollY = y;
                }
                return false;
              },
              child: Stack(
                children: [
                  IndexedStack(
                    index: _currentTab,
                    children: const [
                      PhotoGridView(),
                      AlbumGridView(),
                    ],
                  ),
                  if (_tabVisible && selected.isEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: _FloatingTabBar(
                        currentIndex: _currentTab,
                        onTap: (index) => setState(() => _currentTab = index),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 多选底部栏
          if (selected.isNotEmpty)
            _MultiSelectBar(selected: selected, allIds: allIds),
        ],
      ),
    );
  }
}

class _SpaceTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SpaceTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}


class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: '照片',
              isActive: currentIndex == 0,
              isLeft: true,
              onTap: () => onTap(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: '图集',
              isActive: currentIndex == 1,
              isLeft: false,
              onTap: () => onTap(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLeft;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(16) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _MultiSelectBar extends ConsumerWidget {
  final Set<String> selected;
  final List<String> allIds;

  const _MultiSelectBar({required this.selected, required this.allIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionBtn(
            icon: Icons.share,
            label: '分享',
            onTap: selected.isEmpty
                ? null
                : () => _sharePhotos(ref, selected.toList(), context),
          ),
          _ActionBtn(
            icon: Icons.download,
            label: '下载',
            onTap: selected.isEmpty
                ? null
                : () => _downloadPhotos(ref, selected.toList(), context),
          ),
          _ActionBtn(
            icon: Icons.delete_outline,
            label: '删除',
            color: Colors.red,
            onTap: selected.isEmpty
                ? null
                : () => _deletePhotos(ref, selected.toList(), context),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePhotos(WidgetRef ref, List<String> ids, BuildContext ctx) async {
    for (final id in ids) {
      try {
        final url = await ref.read(photoDownloadUrlProvider(id).future);
        await Share.shareUri(Uri.parse(url));
      } catch (e) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
        break;
      }
    }
  }

  Future<void> _downloadPhotos(WidgetRef ref, List<String> ids, BuildContext ctx) async {
    int count = 0;
    for (final id in ids) {
      try {
        final url = await ref.read(photoDownloadUrlProvider(id).future);
        final bdTask = DownloadTask(
          taskId: 'photo_$id',
          url: url,
          filename: '$id.jpg',
        );
        await FileDownloader().enqueue(bdTask);
        count++;
      } catch (e) {
        // skip failed
      }
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('已添加 $count 个下载任务')),
      );
    }
  }

  Future<void> _deletePhotos(WidgetRef ref, List<String> ids, BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${ids.length} 项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(photoBatchDeleteProvider(ids).future);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('已删除 ${ids.length} 项')),
          );
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
      ref.read(photoMultiSelectProvider.notifier).clear();
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onTap;
    return GestureDetector(
      onTap: effectiveOnTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.grey[700], size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
