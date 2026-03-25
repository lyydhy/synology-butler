import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/information_center.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final informationCenterProvider = FutureProvider<InformationCenterData>((ref) async {
  return ref.read(systemRepositoryProvider).fetchInformationCenter();
});
