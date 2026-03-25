import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/business_connection_context.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/server_url_helper.dart';
import 'auth_providers.dart';

final businessConnectionContextProvider = Provider<BusinessConnectionContext>((ref) {
  final server = ref.watch(currentServerProvider);
  final session = ref.watch(currentSessionProvider);

  if (server == null || session == null) {
    throw Exception('No active NAS session');
  }

  return BusinessConnectionContext(
    server: server,
    session: session,
    baseUrl: ServerUrlHelper.buildBaseUrl(server),
  );
});

final businessDioProvider = Provider<Dio>((ref) {
  final context = ref.watch(businessConnectionContextProvider);
  return DioClient(baseUrl: context.baseUrl).dio;
});
