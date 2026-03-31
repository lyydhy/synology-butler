import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/shared_folder.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final sharedFoldersProvider = FutureProvider<List<SharedFolder>>((ref) async {
  return ref.read(systemRepositoryProvider).fetchSharedFolders();
});
