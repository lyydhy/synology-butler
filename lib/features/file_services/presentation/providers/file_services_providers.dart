import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/file_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final fileServicesProvider = FutureProvider<FileServicesModel>((ref) async {
  return ref.read(systemRepositoryProvider).fetchFileServices();
});

/// 传输日志状态
final transferLogStatusProvider = FutureProvider<Map<String, bool>>((ref) async {
  return ref.read(systemRepositoryProvider).fetchTransferLogStatus();
});
