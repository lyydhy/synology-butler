import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/file_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final fileServicesProvider = FutureProvider<FileServicesModel>((ref) async {
  return ref.read(systemRepositoryProvider).fetchFileServices();
});
