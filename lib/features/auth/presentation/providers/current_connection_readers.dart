import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_dio.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../domain/entities/nas_session.dart';

final activeServerProvider = Provider<NasServer?>((ref) => AppDioFactory.connectionStore.server);
final activeSessionProvider = Provider<NasSession?>((ref) => AppDioFactory.connectionStore.session);
