import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_providers.dart';

final textFileProvider = FutureProvider.family<String, String>((ref, path) async {
  return ref.read(fileRepositoryProvider).readTextFile(
        path: path,
      );
});

final saveTextFileProvider = Provider<Future<void> Function(String path, String content)>((ref) {
  return (path, content) async {
    await ref.read(fileRepositoryProvider).writeTextFile(
          path: path,
          content: content,
        );
  };
});
