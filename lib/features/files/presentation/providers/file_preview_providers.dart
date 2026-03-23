import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'file_providers.dart';

final fileBytesProvider = FutureProvider.family<List<int>, String>((ref, path) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);
  if (server == null || session == null) throw Exception('No active NAS session');

  final bytes = await ref.read(fileRepositoryProvider).downloadFile(
        server: server,
        session: session,
        path: path,
      );
  return bytes;
});
