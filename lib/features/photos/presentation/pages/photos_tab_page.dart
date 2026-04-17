import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/sliding_tab_bar.dart';
import '../providers/photos_providers.dart';
import '../widgets/photo_grid_view.dart';
import '../widgets/album_grid_view.dart';

class PhotosTabPage extends ConsumerStatefulWidget {
  const PhotosTabPage({super.key});

  @override
  ConsumerState<PhotosTabPage> createState() => _PhotosTabPageState();
}

class _PhotosTabPageState extends ConsumerState<PhotosTabPage> {
  late PageController _spacePageController;
  int _currentSpace = 0; // 0=个人空间, 1=共享空间

  // 每个 Space 内的 Tab 状态
  final List<int> _currentTab = [0, 0];
  final List<bool> _tabVisible = [true, true];
  final List<PageController> _tabPageControllers = [PageController(), PageController()];

  @override
  void initState() {
    super.initState();
    _spacePageController = PageController();
  }

  @override
  void dispose() {
    _spacePageController.dispose();
    for (final c in _tabPageControllers) c.dispose();
    super.dispose();
  }

  void _switchSpace(int index) {
    _spacePageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _switchTab(int spaceIndex, int tabIndex) {
    _tabPageControllers[spaceIndex].animateToPage(
      tabIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onSpacePageChanged(int index) {
    setState(() => _currentSpace = index);
    ref.invalidate(photoTimelineAllProvider);
    ref.invalidate(photoAlbumsAllProvider);
  }

  void _updateTabVisible(int spaceIndex, double y, double lastY) {
    if (y > lastY && y > 80 && _tabVisible[spaceIndex]) {
      setState(() => _tabVisible[spaceIndex] = false);
    } else if (y < lastY && !_tabVisible[spaceIndex]) {
      setState(() => _tabVisible[spaceIndex] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(photoMultiSelectProvider);
    final allIds = _currentTab[_currentSpace] == 0
        ? (ref.watch(photoTimelineAllProvider).valueOrNull?.map((e) => e.id).toList() ?? [])
        : (ref.watch(photoAlbumsAllProvider).valueOrNull?.map((e) => e.id).toList() ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 顶部 AppBar
          _PhotosAppBar(
            selected: selected,
            allIds: allIds,
            currentSpace: _currentSpace,
          ),

          // Space 切换（SlidingTabBar）
          if (selected.isEmpty)
            SlidingTabBar(
              pageController: _spacePageController,
              tabs: const [
                SlidingTabItem(icon: Icons.person, label: '个人空间'),
                SlidingTabItem(icon: Icons.group, label: '共享空间'),
              ],
              onTabSelected: (index) => _switchSpace(index),
              height: 48,
              indicatorBorderRadius: 14,
            ),

          if (selected.isEmpty) const Divider(height: 1),

          // Space 内容 PageView
          Expanded(
            child: PageView(
              controller: _spacePageController,
              onPageChanged: _onSpacePageChanged,
              children: [
                _SpaceContent(
                  tabController: _tabPageControllers[0],
                  currentTab: _currentTab[0],
                  tabVisible: _tabVisible[0],
                  onTabChanged: (t) => setState(() => _currentTab[0] = t),
                  onTabSwitch: (t) => _switchTab(0, t),
                ),
                _SpaceContent(
                  tabController: _tabPageControllers[1],
                  currentTab: _currentTab[1],
                  tabVisible: _tabVisible[1],
                  onTabChanged: (t) => setState(() => _currentTab[1] = t),
                  onTabSwitch: (t) => _switchTab(1, t),
                ),
              ],
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

/// AppBar
class _PhotosAppBar extends ConsumerWidget {
  final Set<String> selected;
  final List<String> allIds;
  final int currentSpace;

  const _PhotosAppBar({required this.selected, required this.allIds, required this.currentSpace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          if (selected.isEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => ref.read(photoMultiSelectProvider.notifier).clear(),
            ),
          Expanded(
            child: Text(
              selected.isNotEmpty
                  ? '已选择 ${selected.length} 项'
                  : currentSpace == 0 ? '相册' : '共享空间',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          if (selected.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => context.push('/photos/search'),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                allIds.isNotEmpty && selected.length == allIds.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: Colors.white,
              ),
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
    );
  }
}

/// 单个 Space 的内容（Tab + PageView）
class _SpaceContent extends StatelessWidget {
  final PageController tabController;
  final int currentTab;
  final bool tabVisible;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<int> onTabSwitch;

  const _SpaceContent({
    required this.tabController,
    required this.currentTab,
    required this.tabVisible,
    required this.onTabChanged,
    required this.onTabSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: tabController,
          onPageChanged: onTabChanged,
          children: const [
            PhotoGridView(),
            AlbumGridView(),
          ],
        ),
        if (tabVisible)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _FloatingTabBar(
              currentIndex: currentTab,
              onTap: onTabSwitch,
            ),
          ),
      ],
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

  const _ActionBtn({required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.grey[700], size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey[600])),
        ],
      ),
    );
  }
}
