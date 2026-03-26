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

class _SlidingTabBarState extends State<SlidingTabBar> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChange);
    widget.tabController.animation?.addListener(_onAnimationTick);
  }

  @override
  void didUpdateWidget(covariant SlidingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabController == widget.tabController) {
      return;
    }
    oldWidget.tabController.removeListener(_onTabChange);
    oldWidget.tabController.animation?.removeListener(_onAnimationTick);
    widget.tabController.addListener(_onTabChange);
    widget.tabController.animation?.addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChange);
    widget.tabController.animation?.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onTabChange() {
    if (!mounted) return;
    setState(() {});
    if (widget.tabController.indexIsChanging == false) {
      widget.onTabSelected?.call(widget.tabController.index);
    }
  }

  void _onAnimationTick() {
    if (!mounted) return;
    setState(() {});
  }

  double _currentPageValue() {
    final animation = widget.tabController.animation;
    if (animation == null) {
      return widget.tabController.index.toDouble();
    }
    return animation.value.clamp(0.0, (widget.tabs.length - 1).toDouble());
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

          final currentPage = _currentPageValue();
          final normalizedProgress = widget.tabs.length > 1 ? currentPage / (widget.tabs.length - 1) : 0.0;
          final offset = normalizedProgress * (totalWidth - tabWidth);

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
                  final distance = (currentPage - index).abs();
                  final selection = (1 - distance).clamp(0.0, 1.0);
                  final iconColor = Color.lerp(
                    unselectedClr.withValues(alpha: 0.6),
                    selectedClr,
                    selection,
                  )!;
                  final textColor = Color.lerp(
                    unselectedClr.withValues(alpha: 0.6),
                    selectedClr,
                    selection,
                  )!;
                  final fontWeight = selection > 0.5 ? FontWeight.w700 : widget.fontWeight;

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
                              color: iconColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: fontWeight,
                                color: textColor,
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
