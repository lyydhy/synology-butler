import 'dart:ui';

import 'package:flutter/material.dart';

/// A polished sliding-tab bar with animated indicator and icon + label support.
class SlidingTabBar extends StatefulWidget {
  const SlidingTabBar({
    super.key,
    this.tabController,
    this.pageController,
    required this.tabs,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.height = 56,
    this.iconSize = 18,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.indicatorBorderRadius = 18,
    this.horizontalPadding = 6,
    this.onTabSelected,
  }) : assert(tabController != null || pageController != null,
            'Either tabController or pageController must be provided');

  /// TabController for TabBarView-based usage.
  final TabController? tabController;

  /// PageController for PageView-based usage.
  final PageController? pageController;

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
  TabController? get _tabController => widget.tabController;
  PageController? get _pageController => widget.pageController;
  bool get _isPageController => widget.pageController != null;

  int get _currentIndex {
    if (_isPageController) {
      return _pageController!.page?.round() ?? _pageController!.initialPage;
    }
    return _tabController!.index;
  }

  double get _currentPageValue {
    if (_isPageController) {
      return _pageController!.position.pixels == 0 && _pageController!.page == null
          ? _pageController!.initialPage.toDouble()
          : (_pageController!.page ?? _pageController!.initialPage.toDouble());
    }
    final animation = _tabController!.animation;
    if (animation == null) {
      return _tabController!.index.toDouble();
    }
    return animation.value.clamp(0.0, (widget.tabs.length - 1).toDouble());
  }

  void _animateTo(int index) {
    if (_isPageController) {
      _pageController!.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _tabController!.animateTo(index);
    }
  }

  void _onTabChange() {
    if (!mounted) return;
    setState(() {});
    if (_isPageController) {
      widget.onTabSelected?.call(_currentIndex);
    } else if (!_tabController!.indexIsChanging) {
      widget.onTabSelected?.call(_tabController!.index);
    }
  }

  void _onAnimationTick() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (_isPageController) {
      _pageController!.addListener(_onPageListener);
    } else {
      _tabController!.addListener(_onTabChange);
      _tabController!.animation?.addListener(_onAnimationTick);
    }
  }

  void _onPageListener() {
    _onAnimationTick();
  }

  @override
  void didUpdateWidget(covariant SlidingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isPageController) {
      if (oldWidget.pageController != widget.pageController) {
        oldWidget.pageController?.removeListener(_onPageListener);
        widget.pageController?.addListener(_onPageListener);
      }
    } else {
      if (oldWidget.tabController != widget.tabController) {
        oldWidget.tabController?.removeListener(_onTabChange);
        oldWidget.tabController?.animation?.removeListener(_onAnimationTick);
        _tabController?.addListener(_onTabChange);
        _tabController?.animation?.addListener(_onAnimationTick);
      }
    }
  }

  @override
  void dispose() {
    if (_isPageController) {
      _pageController?.removeListener(_onPageListener);
    } else {
      _tabController?.removeListener(_onTabChange);
      _tabController?.animation?.removeListener(_onAnimationTick);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow);
    final selectedClr = widget.selectedColor ?? scheme.primary;
    final unselectedClr = widget.unselectedColor ?? scheme.onSurfaceVariant;
    final indicatorClr = widget.indicatorColor ??
        (isDark ? scheme.surfaceContainerHighest : scheme.surface);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.32)
              : scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / widget.tabs.length;
          final indicatorWidth = tabWidth - widget.horizontalPadding * 2;

          final currentPage = _currentPageValue;
          final normalizedProgress = widget.tabs.length > 1 ? currentPage / (widget.tabs.length - 1) : 0.0;
          final offset = normalizedProgress * (totalWidth - tabWidth);

          return Stack(
            children: [
              Positioned(
                left: offset + widget.horizontalPadding,
                top: 5,
                width: indicatorWidth,
                height: widget.height - 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: indicatorClr,
                    borderRadius: BorderRadius.circular(widget.indicatorBorderRadius),
                    border: Border.all(
                      color: selectedClr.withValues(alpha: isDark ? 0.14 : 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.035),
                        blurRadius: isDark ? 10 : 6,
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
                  final easedSelection = Curves.easeOutCubic.transform(selection);
                  final contentColor = Color.lerp(
                    unselectedClr.withValues(alpha: isDark ? 0.82 : 0.78),
                    selectedClr,
                    easedSelection,
                  )!;
                  final labelWeight = selection > 0.55 ? FontWeight.w700 : widget.fontWeight;
                  final scale = lerpDouble(0.985, 1.0, easedSelection) ?? 1.0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _animateTo(index);
                        widget.onTabSelected?.call(index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Transform.translate(
                          offset: const Offset(0, 1),
                          child: SizedBox(
                            height: widget.height,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: widget.iconSize,
                                    color: contentColor,
                                  ),
                                  if (tab.badge != null && tab.badge!.isNotEmpty)
                                    Positioned(
                                      top: -6,
                                      right: -10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        decoration: BoxDecoration(
                                          color: selectedClr,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          tab.badge!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            height: 1,
                                            fontWeight: FontWeight.w800,
                                            color: scheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: widget.fontSize,
                                  fontWeight: labelWeight,
                                  color: contentColor,
                                  letterSpacing: 0.1,
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
