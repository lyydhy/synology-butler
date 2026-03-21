import 'package:flutter/material.dart';

typedef BreadcrumbSegment = ({String label, String path, bool current});

class PathBreadcrumb extends StatelessWidget {
  const PathBreadcrumb({
    super.key,
    required this.path,
    required this.onTapSegment,
  });

  final String path;
  final ValueChanged<String> onTapSegment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = path == '/'
        ? <BreadcrumbSegment>[
            (label: '/', path: '/', current: true),
          ]
        : _buildSegments(path);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            _BreadcrumbNode(
              label: segments[i].label,
              current: segments[i].current,
              onTap: () => onTapSegment(segments[i].path),
            ),
            if (i != segments.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
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
            horizontal: label == '/' ? 12 : 14,
            vertical: 8,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
