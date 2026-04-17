import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/api/synology_photos_api.dart';
import '../providers/photos_providers.dart';
import '../widgets/photo_grid_view.dart';
import '../widgets/album_grid_view.dart';

class PhotosTabPage extends ConsumerStatefulWidget {
  const PhotosTabPage({super.key});

  @override
  ConsumerState<PhotosTabPage> createState() => _PhotosTabPageState();
}

class _PhotosTabPageState extends ConsumerState<PhotosTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentSpace = 0; // 0=个人空间, 1=共享空间

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Tab 切换时刷新对应数据
      setState(() {});
    }
  }

  void _switchSpace(int index) {
    if (_currentSpace == index) return;
    setState(() => _currentSpace = index);
    ref.invalidate(photoTimelineAllProvider);
    ref.invalidate(photoAlbumsAllProvider);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(photoMultiSelectProvider);
    final timelineState = ref.watch(photoTimelineAllProvider);
    final albumsState = ref.watch(photoAlbumsAllProvider);
    final timeline = timelineState.valueOrNull ?? [];
    final albums = albumsState.valueOrNull ?? [];
    final List<FotoItem> currentItems = _tabController.index == 0 ? (timeline as List<FotoItem>) : (albums as List<FotoItem>);
    final allIds = currentItems.map<String>((e) => e.id).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          selected.isNotEmpty
              ? '已选择 ${selected.length} 项'
              : _currentSpace == 0 ? '相册' : '共享空间',
        ),
        leading: selected.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(photoMultiSelectProvider.notifier).clear(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        actions: [
          if (selected.isEmpty) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/photos/search'),
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                allIds.isNotEmpty && selected.length == allIds.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
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
        bottom: selected.isEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(96),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Space 切换
                    _SpaceToggle(
                      currentSpace: _currentSpace,
                      onSwitch: _switchSpace,
                    ),
                    // 照片/图集 Tab
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        tabs: const [
                          Tab(text: '照片'),
                          Tab(text: '图集'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
      body: selected.isNotEmpty
          ? const SizedBox()
          : TabBarView(
              controller: _tabController,
              children: [
                PhotoGridView(key: ValueKey('photo_$_currentSpace')),
                AlbumGridView(key: ValueKey('album_$_currentSpace')),
              ],
            ),
      bottomNavigationBar: selected.isNotEmpty
          ? _MultiSelectBar(selected: selected, allIds: allIds)
          : null,
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
            onTap: selected.isEmpty ? null : () => _share(ref, context),
          ),
          _ActionBtn(
            icon: Icons.download,
            label: '下载',
            onTap: selected.isEmpty ? null : () => _download(ref, context),
          ),
          _ActionBtn(
            icon: Icons.delete_outline,
            label: '删除',
            color: Colors.red,
            onTap: selected.isEmpty ? null : () => _delete(ref, context),
          ),
        ],
      ),
    );
  }

  Future<void> _share(WidgetRef ref, BuildContext ctx) async {
    for (final id in selected.toList()) {
      try {
        final url = await ref.read(photoDownloadUrlProvider(id).future);
        await Share.shareUri(Uri.parse(url));
      } catch (e) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('分享失败: $e')));
        break;
      }
    }
  }

  Future<void> _download(WidgetRef ref, BuildContext ctx) async {
    int count = 0;
    for (final id in selected.toList()) {
      try {
        final url = await ref.read(photoDownloadUrlProvider(id).future);
        await FileDownloader().enqueue(DownloadTask(taskId: 'photo_$id', url: url, filename: '$id.jpg'));
        count++;
      } catch (_) {}
    }
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('已添加 $count 个下载任务')));
    }
  }

  Future<void> _delete(WidgetRef ref, BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${selected.length} 项吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(photoBatchDeleteProvider(selected.toList()).future);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('已删除 ${selected.length} 项')));
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
      ref.read(photoMultiSelectProvider.notifier).clear();
    }
  }
}

class _SpaceToggle extends StatelessWidget {
  final int currentSpace;
  final ValueChanged<int> onSwitch;

  const _SpaceToggle({required this.currentSpace, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onSwitch(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentSpace == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: currentSpace == 0
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 2)]
                      : null,
                ),
                child: Text(
                  '个人空间',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: currentSpace == 0 ? FontWeight.w600 : FontWeight.normal,
                    color: currentSpace == 0 ? Theme.of(context).primaryColor : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onSwitch(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentSpace == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: currentSpace == 1
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 2)]
                      : null,
                ),
                child: Text(
                  '共享空间',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: currentSpace == 1 ? FontWeight.w600 : FontWeight.normal,
                    color: currentSpace == 1 ? Theme.of(context).primaryColor : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
