import 'package:flutter/material.dart';

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
    final segments = path == '/'
        ? <String>['/']
        : path.split('/').where((e) => e.isNotEmpty).toList();

    if (segments.length == 1 && segments.first == '/') {
      return Wrap(
        spacing: 4,
        children: [
          ActionChip(label: const Text('/'), onPressed: () => onTapSegment('/')),
        ],
      );
    }

    final widgets = <Widget>[
      ActionChip(label: const Text('/'), onPressed: () => onTapSegment('/')),
    ];

    var current = '';
    for (final segment in segments) {
      current += '/$segment';
      widgets.add(const Text('/'));
      widgets.add(ActionChip(label: Text(segment), onPressed: () => onTapSegment(current)));
    }

    return Wrap(spacing: 4, runSpacing: 4, children: widgets);
  }
}
