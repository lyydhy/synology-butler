import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/index_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final indexServiceProvider = FutureProvider<IndexServiceData>((ref) async {
  return ref.read(systemRepositoryProvider).fetchIndexService();
});

final indexServiceBusyProvider = StateProvider<bool>((ref) => false);

final setThumbnailQualityProvider = Provider<Future<void> Function(int quality)>((ref) {
  return (int quality) async {
    ref.read(indexServiceBusyProvider.notifier).state = true;
    try {
      await ref.read(systemRepositoryProvider).setThumbnailQuality(quality: quality);
      ref.invalidate(indexServiceProvider);
    } finally {
      ref.read(indexServiceBusyProvider.notifier).state = false;
    }
  };
});

final rebuildIndexProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.read(indexServiceBusyProvider.notifier).state = true;
    try {
      await ref.read(systemRepositoryProvider).rebuildIndex();
      ref.invalidate(indexServiceProvider);
    } finally {
      ref.read(indexServiceBusyProvider.notifier).state = false;
    }
  };
});
