import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/api/package_api.dart';
import '../../../../data/repositories/package_repository_impl.dart';
import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/package_volume.dart';
import '../../../../domain/repositories/package_repository.dart';
import '../state/package_install_state.dart';

final packageApiProvider = Provider<PackageApi>((ref) {
  return DsmPackageApi();
});

