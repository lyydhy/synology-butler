import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_providers.dart';

final fileBytesProvider = FutureProvider.family<List<int>, String>((ref, path) async {
  final bytes = await ref.read(fileRepositoryProvider).downloadFile(
        path: path,
      );
  return bytes;
});
