import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/current_connection_store.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../domain/entities/nas_session.dart';
import 'auth_providers.dart';

final currentConnectionStoreProvider = ChangeNotifierProvider<CurrentConnectionStore>((ref) {
  return connectionStore;
});

class CurrentConnectionSnapshot {
  const CurrentConnectionSnapshot({
    required this.server,
    required this.session,
    this.username,
    this.password,
  });

  final NasServer? server;
  final NasSession? session;
  final String? username;
  final String? password;

  bool get hasSession => server != null && session != null;

  String get baseUrl {
    final currentServer = server;
    if (currentServer == null) return '';
    final scheme = currentServer.https ? 'https' : 'http';
    final host = currentServer.host.trim().replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/$'), '');
    final basePath =
        (currentServer.basePath == null || currentServer.basePath!.trim().isEmpty)
            ? ''
            : (currentServer.basePath!.startsWith('/') ? currentServer.basePath! : '/${currentServer.basePath!}');
    return '$scheme://$host:${currentServer.port}$basePath';
  }

  String get host => server?.host ?? '';

  int? get port => server?.port;

  String? get sid => session?.sid;

  String? get synoToken => session?.synoToken;
}

final currentConnectionProvider = Provider<CurrentConnectionSnapshot>((ref) {
  ref.watch(currentConnectionStoreProvider);

  final session = connectionStore.session;
  final stored = connectionStore.credentials;
  final username = session?.username ?? stored?.username ?? ref.watch(savedUsernameProvider);
  final password = session?.password ?? stored?.password ?? ref.watch(savedPasswordProvider);

  return CurrentConnectionSnapshot(
    server: connectionStore.server,
    session: session,
    username: username,
    password: password,
  );
});

