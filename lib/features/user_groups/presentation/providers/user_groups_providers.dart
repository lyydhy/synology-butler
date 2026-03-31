import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/dsm_group.dart';
import '../../../../domain/entities/dsm_user.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final usersProvider = FutureProvider<List<DsmUser>>((ref) async {
  return ref.read(systemRepositoryProvider).fetchUsers();
});

final groupsProvider = FutureProvider<List<DsmGroup>>((ref) async {
  return ref.read(systemRepositoryProvider).fetchGroups();
});
