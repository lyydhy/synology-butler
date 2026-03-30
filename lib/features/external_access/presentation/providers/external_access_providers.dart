import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/external_access.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final externalAccessProvider = FutureProvider<ExternalAccessData>((ref) async {
  return ref.read(systemRepositoryProvider).fetchExternalAccess();
});

final ddnsRefreshControllerProvider = StateProvider<bool>((ref) => false);

final refreshDdnsProvider = Provider<Future<void> Function({String? recordId})>((ref) {
  return ({String? recordId}) async {
    ref.read(ddnsRefreshControllerProvider.notifier).state = true;
    try {
      await ref.read(systemRepositoryProvider).refreshDdns(recordId: recordId);
      ref.invalidate(externalAccessProvider);
    } finally {
      ref.read(ddnsRefreshControllerProvider.notifier).state = false;
    }
  };
});
