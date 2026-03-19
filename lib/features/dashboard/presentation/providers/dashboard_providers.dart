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

final dashboardBaseOverviewProvider = FutureProvider<SystemStatus>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  return ref.read(systemRepositoryProvider).fetchOverview(
        server: server,
        session: session,
      );
});

final dashboardRealtimeOverviewProvider = StreamProvider<SystemStatus>((ref) {
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
  final baseOverview = ref.watch(dashboardBaseOverviewProvider);
  final realtimeOverview = ref.watch(dashboardRealtimeOverviewProvider);

  if (realtimeOverview.hasValue) {
    final realtime = realtimeOverview.value!;
    final base = baseOverview.valueOrNull;

    return AsyncValue.data(
      SystemStatus(
        serverName: base?.serverName ?? realtime.serverName,
        dsmVersion: base?.dsmVersion ?? realtime.dsmVersion,
        cpuUsage: realtime.cpuUsage,
        memoryUsage: realtime.memoryUsage,
        storageUsage: realtime.storageUsage,
        modelName: base?.modelName ?? realtime.modelName,
        serialNumber: base?.serialNumber ?? realtime.serialNumber,
        uptimeText: base?.uptimeText ?? realtime.uptimeText,
      ),
    );
  }

  if (baseOverview.hasValue) {
    return AsyncValue.data(baseOverview.value);
  }

  if (baseOverview.isLoading) {
    return const AsyncValue.loading();
  }

  return const AsyncValue.data(null);
});
