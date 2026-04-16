import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_providers.dart';
import 'code_language.dart';

export 'code_language.dart' show codeEditorStyle, buildSingleLanguageTheme, getLanguageDisplayName;

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

/// 根据文件名获取语言显示名
final fileLanguageNameProvider = Provider.family<String, String>((ref, filename) {
  return getLanguageDisplayName(getModeByFilename(filename).name ?? 'plaintext');
});
