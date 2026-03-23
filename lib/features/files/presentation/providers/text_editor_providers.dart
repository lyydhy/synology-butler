import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'file_providers.dart';

final textFileProvider = FutureProvider.family<String, String>((ref, path) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);
  if (server == null || session == null) throw Exception('No active NAS session');

  return ref.read(fileRepositoryProvider).readTextFile(
        server: server,
        session: session,
        path: path,
      );
});

final saveTextFileProvider = Provider<Future<void> Function(String path, String content)>((ref) {
  return (path, content) async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);
    if (server == null || session == null) throw Exception('No active NAS session');

    await ref.read(fileRepositoryProvider).writeTextFile(
          server: server,
          session: session,
          path: path,
          content: content,
        );
  };
});
