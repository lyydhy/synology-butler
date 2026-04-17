import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final space = ref.watch(photoSpaceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text(l10n.synologyPhotos),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/photos/search'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Space Switcher
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
                      onTap: () =>
                          ref.read(photoSpaceProvider.notifier).state = PhotoSpace.personal,
                    ),
                  ),
                  Expanded(
                    child: _SpaceTab(
                      label: '共享空间',
                      isActive: space == PhotoSpace.shared,
                      onTap: () =>
                          ref.read(photoSpaceProvider.notifier).state = PhotoSpace.shared,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Access
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _QuickAccessChip(icon: '⭐', label: '收藏'),
                const SizedBox(width: 8),
                _QuickAccessChip(icon: '🕐', label: '最近添加'),
                const SizedBox(width: 8),
                _QuickAccessChip(icon: '📁', label: '文件夹'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Stack(
              children: [
                // Tab content
                IndexedStack(
                  index: _currentTab,
                  children: const [
                    PhotoGridView(),
                    AlbumGridView(),
                  ],
                ),

                // Floating Bottom Tab
                if (_tabVisible)
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _toggleMultiSelect(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.checklist, color: Colors.white),
      ),
    );
  }

  void _toggleMultiSelect() {
    // TODO: multi-select mode
  }
}

class _SpaceTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SpaceTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

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

class _QuickAccessChip extends StatelessWidget {
  final String icon;
  final String label;

  const _QuickAccessChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingTabBar({
    required this.currentIndex,
    required this.onTap,
  });

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
