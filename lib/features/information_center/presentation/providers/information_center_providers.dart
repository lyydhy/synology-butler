import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/information_center.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final informationCenterProvider = FutureProvider<InformationCenterData>((ref) async {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  return ref.read(systemRepositoryProvider).fetchInformationCenter(
        server: server,
        session: session,
      );
});
