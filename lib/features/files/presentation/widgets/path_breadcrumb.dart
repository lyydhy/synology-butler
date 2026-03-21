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
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
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
      final targetPath = current;
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Center(child: Text('/')),
        ),
      );
      widgets.add(
        ActionChip(
          label: Text(segment),
          onPressed: () => onTapSegment(targetPath),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widgets,
    );
  }
}
