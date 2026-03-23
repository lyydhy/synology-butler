import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedFilePathsProvider = StateProvider<Set<String>>((ref) => <String>{});

final fileSelectionModeProvider = Provider<bool>((ref) {
  return ref.watch(selectedFilePathsProvider).isNotEmpty;
});
