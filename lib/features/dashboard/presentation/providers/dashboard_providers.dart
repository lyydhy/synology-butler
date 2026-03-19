import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/system_api.dart';
import '../../../../data/repositories/system_repository_impl.dart';
import '../../../../domain/entities/system_status.dart';
import '../../../../domain/repositories/system_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final systemApiProvider = Provider<SystemApi>((ref) => DsmSystemApi());

final systemRepositoryProvider = Provider<SystemRepository>((ref) {
  return SystemRepositoryImpl(ref.read(systemApiProvider));
});

final dashboardOverviewProvider = StreamProvider<SystemStatus>((ref) {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  return ref.read(systemRepositoryProvider).watchOverview(
        server: server,
        session: session,
      );
});

final dashboardOverviewSafeProvider = Provider<AsyncValue<SystemStatus?>>((ref) {
  final overview = ref.watch(dashboardOverviewProvider);

  return overview.when(
    data: (value) => AsyncValue.data(value),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => const AsyncValue.data(null),
  );
});
