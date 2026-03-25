import 'package:flutter/material.dart';

/// A modern sliding-tab bar with animated indicator and icon + label support.
///
/// Usage:
/// ```dart
/// SlidingTabBar(
///   tabController: tabController,
///   tabs: [
///     SlidingTabItem(icon: Icons.dashboard, label: '概览'),
///     SlidingTabItem(icon: Icons.memory, label: 'CPU'),
///     SlidingTabItem(icon: Icons.storage, label: '存储'),
///   ],
/// )
/// ```
class SlidingTabBar extends StatefulWidget {
  const SlidingTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.height = 52,
    this.iconSize = 18,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.indicatorBorderRadius = 10,
    this.horizontalPadding = 4,
    this.onTabSelected,
  });

  final TabController tabController;
  final List<SlidingTabItem> tabs;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final double height;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;
  final double indicatorBorderRadius;
  final double horizontalPadding;
  final ValueChanged<int>? onTabSelected;

  @override
  State<SlidingTabBar> createState() => _SlidingTabBarState();
}

class _SlidingTabBarState extends State<SlidingTabBar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    widget.tabController.addListener(_onTabChange);
    // Set initial position without animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIndicator(animate: false);
    });
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChange);
    _animController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (!mounted) return;
    _syncIndicator(animate: true);
    if (widget.tabController.indexIsChanging == false) {
      // index change completed
      widget.onTabSelected?.call(widget.tabController.index);
    }
  }

  void _syncIndicator({required bool animate}) {
    final tabCount = widget.tabs.length;
    if (tabCount == 0) return;
    final targetIndex = widget.tabController.index.clamp(0, tabCount - 1);
    final targetProgress = tabCount > 1 ? targetIndex / (tabCount - 1) : 0.0;
    if (animate) {
      _animController.animateTo(targetProgress, duration: const Duration(milliseconds: 220), curve: Curves.easeInOut);
    } else {
      _animController.value = targetProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surfaceContainerLow;
    final selectedClr = widget.selectedColor ?? theme.colorScheme.primary;
    final unselectedClr = widget.unselectedColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / widget.tabs.length;
          final indicatorWidth = tabWidth - widget.horizontalPadding * 2;

          return AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final offset = _animController.value * (totalWidth - tabWidth);
              return Stack(
                children: [
                  // Sliding indicator
                  Positioned(
                    left: offset + widget.horizontalPadding,
                    top: 4,
                    width: indicatorWidth,
                    height: widget.height - 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedClr.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(widget.indicatorBorderRadius),
                        border: Border.all(
                          color: selectedClr.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Tabs row
                  Row(
                    children: List.generate(widget.tabs.length, (index) {
                      final tab = widget.tabs[index];
                      final isSelected = widget.tabController.index == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.tabController.animateTo(index);
                            widget.onTabSelected?.call(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            height: widget.height,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tab.icon,
                                  size: widget.iconSize,
                                  color: isSelected ? selectedClr : unselectedClr.withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  tab.label,
                                  style: TextStyle(
                                    fontSize: widget.fontSize,
                                    fontWeight: isSelected ? FontWeight.w700 : widget.fontWeight,
                                    color: isSelected ? selectedClr : unselectedClr.withValues(alpha: 0.6),
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Configuration for a single tab in [SlidingTabBar].
class SlidingTabItem {
  const SlidingTabItem({
    required this.icon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? badge;
}
