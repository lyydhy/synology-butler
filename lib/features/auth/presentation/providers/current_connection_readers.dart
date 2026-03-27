import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/current_connection_store.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../domain/entities/nas_session.dart';

final currentConnectionStoreProvider = ChangeNotifierProvider<CurrentConnectionStore>((ref) {
  return connectionStore;
});

final activeServerProvider = Provider<NasServer?>((ref) {
  ref.watch(currentConnectionStoreProvider);
  return connectionStore.server;
});

final activeSessionProvider = Provider<NasSession?>((ref) {
  ref.watch(currentConnectionStoreProvider);
  return connectionStore.session;
});
