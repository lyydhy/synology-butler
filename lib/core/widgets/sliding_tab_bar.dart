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
    this.indicatorBorderRadius = 18,
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
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = widget.backgroundColor ??
        (isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.78)
            : scheme.surfaceContainer.withValues(alpha: 0.90));
    final selectedClr = widget.selectedColor ?? scheme.primary;
    final unselectedClr = widget.unselectedColor ?? scheme.onSurfaceVariant;
    final indicatorClr = widget.indicatorColor ??
        (isDark ? scheme.surfaceBright.withValues(alpha: 0.94) : scheme.surface.withValues(alpha: 0.96));

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgColor,
                bgColor.withValues(alpha: isDark ? 0.88 : 0.96),
              ],
            ),
            border: Border.all(
              color: isDark
                  ? scheme.outlineVariant.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                blurRadius: isDark ? 20 : 16,
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
                        borderRadius: BorderRadius.circular(widget.indicatorBorderRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            indicatorClr,
                            indicatorClr.withValues(alpha: isDark ? 0.90 : 0.98),
                          ],
                        ),
                        border: Border.all(
                          color: selectedClr.withValues(alpha: isDark ? 0.16 : 0.12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedClr.withValues(alpha: isDark ? 0.16 : 0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.42),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.height / 2),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: isDark ? 0.02 : 0.18),
                              Colors.transparent,
                            ],
                          ),
                        ),
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
                        unselectedClr.withValues(alpha: isDark ? 0.78 : 0.72),
                        selectedClr,
                        easedSelection,
                      )!;
                      final labelWeight = selection > 0.55 ? FontWeight.w700 : widget.fontWeight;
                      final scale = lerpDouble(0.975, 1.0, easedSelection) ?? 1.0;
                      final verticalOffset = lerpDouble(1.5, 0, easedSelection) ?? 0;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            widget.tabController.animateTo(index);
                            widget.onTabSelected?.call(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedScale(
                            scale: scale,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            child: Transform.translate(
                              offset: Offset(0, verticalOffset),
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
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: selectedClr.withValues(alpha: 0.28),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
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
