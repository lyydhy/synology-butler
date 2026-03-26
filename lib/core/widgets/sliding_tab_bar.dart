import 'dart:ui';

import 'package:flutter/material.dart';

/// A polished sliding-tab bar with animated indicator and icon + label support.
class SlidingTabBar extends StatefulWidget {
  const SlidingTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.height = 56,
    this.iconSize = 18,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.indicatorBorderRadius = 16,
    this.horizontalPadding = 6,
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
    final scheme = theme.colorScheme;
    final bgColor = widget.backgroundColor ?? scheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final selectedClr = widget.selectedColor ?? scheme.primary;
    final unselectedClr = widget.unselectedColor ?? scheme.onSurfaceVariant;
    final indicatorClr = widget.indicatorColor ?? scheme.surface.withValues(alpha: 0.92);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                  Positioned(
                    left: offset + widget.horizontalPadding,
                    top: 6,
                    width: indicatorWidth,
                    height: widget.height - 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: indicatorClr,
                        borderRadius: BorderRadius.circular(widget.indicatorBorderRadius),
                        border: Border.all(
                          color: selectedClr.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedClr.withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.30),
                            blurRadius: 1,
                            spreadRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(widget.tabs.length, (index) {
                      final tab = widget.tabs[index];
                      final distance = (currentPage - index).abs();
                      final selection = (1 - distance).clamp(0.0, 1.0);
                      final contentColor = Color.lerp(
                        unselectedClr.withValues(alpha: 0.72),
                        selectedClr,
                        Curves.easeOut.transform(selection),
                      )!;
                      final labelWeight = selection > 0.55 ? FontWeight.w700 : widget.fontWeight;
                      final scale = lerpDouble(0.98, 1.0, selection) ?? 1.0;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.tabController.animateTo(index);
                            widget.onTabSelected?.call(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            child: SizedBox(
                              height: widget.height,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: widget.iconSize,
                                    color: contentColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tab.label,
                                    style: TextStyle(
                                      fontSize: widget.fontSize,
                                      fontWeight: labelWeight,
                                      color: contentColor,
                                      letterSpacing: 0.15,
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}

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
