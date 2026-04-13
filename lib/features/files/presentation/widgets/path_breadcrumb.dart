import 'package:flutter/material.dart';

typedef BreadcrumbSegment = ({String label, String path, bool current});

class PathBreadcrumb extends StatefulWidget {
  const PathBreadcrumb({
    super.key,
    required this.path,
    required this.onTapSegment,
    this.onGoUp,
  });

  final String path;
  final ValueChanged<String> onTapSegment;
  final VoidCallback? onGoUp;

  @override
  State<PathBreadcrumb> createState() => _PathBreadcrumbState();
}

class _PathBreadcrumbState extends State<PathBreadcrumb> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 首次渲染后滚动到最右侧（显示最新路径）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(PathBreadcrumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 路径变化时滚动到最右侧
    if (oldWidget.path != widget.path) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = widget.path == '/'
        ? <BreadcrumbSegment>[
            (label: '/', path: '/', current: true),
          ]
        : _buildSegments(widget.path);

    return Row(
      children: [
        if (widget.onGoUp != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: widget.onGoUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.subdirectory_arrow_left_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text('..', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < segments.length; i++) ...[
                  _BreadcrumbNode(
                    label: segments[i].label,
                    current: segments[i].current,
                    onTap: () => widget.onTapSegment(segments[i].path),
                  ),
                  if (i != segments.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<BreadcrumbSegment> _buildSegments(String rawPath) {
    final parts = rawPath.split('/').where((e) => e.isNotEmpty).toList();
    final result = <BreadcrumbSegment>[
      (label: '/', path: '/', current: parts.isEmpty),
    ];

    var currentPath = '';
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      currentPath += '/$part';
      result.add(
        (label: part, path: currentPath, current: i == parts.length - 1),
      );
    }

    return result;
  }
}

class _BreadcrumbNode extends StatelessWidget {
  const _BreadcrumbNode({
    required this.label,
    required this.current,
    required this.onTap,
  });

  final String label;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = current ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final foregroundColor = current ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == '/' ? 10 : 12,
            vertical: 4,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
