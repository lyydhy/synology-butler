import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/server_mapper.dart';
import '../../../../data/api/dsm_auth_api.dart';
import '../../../../data/models/nas_server_model.dart';
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../domain/entities/nas_session.dart';
import '../../../../domain/repositories/auth_repository.dart';

final authApiProvider = Provider((ref) => DsmAuthApi());
final localStorageProvider = Provider((ref) => LocalStorageService());
final secureStorageProvider = Provider((ref) => const SecureStorageService(FlutterSecureStorage()));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authApiProvider));
});

final savedServersProvider = StateProvider<List<NasServer>>((ref) => []);
final savedUsernameProvider = StateProvider<String?>((ref) => null);
final currentServerProvider = StateProvider<NasServer?>((ref) => null);
final currentSessionProvider = StateProvider<NasSession?>((ref) => null);

Future<void> _persistServers(Ref ref, List<NasServer> servers) async {
  final localStorage = ref.read(localStorageProvider);
  final encoded = servers.map((s) => ServerMapper.toModel(s).encode()).toList();
  await localStorage.writeStringList(AppConstants.savedServersKey, encoded);
}

final restoreSessionProvider = FutureProvider<bool>((ref) async {
  final localStorage = ref.read(localStorageProvider);
  final secureStorage = ref.read(secureStorageProvider);

  final savedServers = await localStorage.readStringList(AppConstants.savedServersKey);
  final currentServerId = await localStorage.readString(AppConstants.savedCurrentServerIdKey);
  final savedSid = await secureStorage.read(AppConstants.savedSidKey);
  final savedSynoToken = await secureStorage.read(AppConstants.savedSynoTokenKey);
  final savedCookieHeader = await secureStorage.read(AppConstants.savedCookieHeaderKey);
  final savedRequestHashSeed = await secureStorage.read(AppConstants.savedRequestHashSeedKey);
  final savedAuthToken = await secureStorage.read(AppConstants.savedAuthTokenKey);
  final savedUsername = await localStorage.readString(AppConstants.savedUsernameKey);

  ref.read(savedUsernameProvider.notifier).state = savedUsername;

  final servers = savedServers.map(NasServerModel.decode).map(ServerMapper.toEntity).toList();

  ref.read(savedServersProvider.notifier).state = servers;

  if (currentServerId == null || savedSid == null || savedSid.isEmpty) {
    return false;
  }

  final matched = servers.where((s) => s.id == currentServerId);
  if (matched.isEmpty) {
    return false;
  }
  final currentServer = matched.first;

  ref.read(currentServerProvider.notifier).state = currentServer;
  ref.read(currentSessionProvider.notifier).state = NasSession(
        serverId: currentServer.id,
        sid: savedSid,
        synoToken: savedSynoToken,
        cookieHeader: savedCookieHeader,
        requestHashSeed: savedRequestHashSeed,
        authToken: savedAuthToken,
      );

  return true;
});

final clearSessionProvider = Provider<Future<void> Function({bool markExpired})>((ref) {
  return ({bool markExpired = false}) async {
    ref.read(currentSessionProvider.notifier).state = null;

    final localStorage = ref.read(localStorageProvider);
    final secureStorage = ref.read(secureStorageProvider);

    if (markExpired) {
      await localStorage.writeString(AppConstants.sessionExpiredFlagKey, '1');
    } else {
      await localStorage.remove(AppConstants.sessionExpiredFlagKey);
    }

    await secureStorage.delete(AppConstants.savedSidKey);
    await secureStorage.delete(AppConstants.savedSynoTokenKey);
    await secureStorage.delete(AppConstants.savedCookieHeaderKey);
    await secureStorage.delete(AppConstants.savedRequestHashSeedKey);
    await secureStorage.delete(AppConstants.savedAuthTokenKey);
  };
});

final persistLoginProvider = Provider<Future<void> Function(NasServer, NasSession, String)>((ref) {
  return (server, session, username) async {
    final localStorage = ref.read(localStorageProvider);
    final secureStorage = ref.read(secureStorageProvider);

    final existing = [...ref.read(savedServersProvider)];
    final index = existing.indexWhere((s) => s.id == server.id);
    if (index >= 0) {
      existing[index] = server;
    } else {
      existing.add(server);
    }
    ref.read(savedServersProvider.notifier).state = existing;
    ref.read(savedUsernameProvider.notifier).state = username;

    await _persistServers(ref, existing);
    await localStorage.writeString(AppConstants.savedCurrentServerIdKey, server.id);
    await localStorage.writeString(AppConstants.savedUsernameKey, username);
    await localStorage.remove(AppConstants.sessionExpiredFlagKey);
    await secureStorage.write(AppConstants.savedSidKey, session.sid);
    if (session.synoToken != null && session.synoToken!.isNotEmpty) {
      await secureStorage.write(AppConstants.savedSynoTokenKey, session.synoToken!);
    }
    if (session.cookieHeader != null && session.cookieHeader!.isNotEmpty) {
      await secureStorage.write(AppConstants.savedCookieHeaderKey, session.cookieHeader!);
    }
    if (session.requestHashSeed != null && session.requestHashSeed!.isNotEmpty) {
      await secureStorage.write(AppConstants.savedRequestHashSeedKey, session.requestHashSeed!);
    }
    if (session.authToken != null && session.authToken!.isNotEmpty) {
      await secureStorage.write(AppConstants.savedAuthTokenKey, session.authToken!);
    }
  };
});

final switchCurrentServerProvider = Provider<Future<void> Function(NasServer)>((ref) {
  return (server) async {
    ref.read(currentServerProvider.notifier).state = server;
    ref.read(currentSessionProvider.notifier).state = null;
    final localStorage = ref.read(localStorageProvider);
    final secureStorage = ref.read(secureStorageProvider);
    await localStorage.writeString(AppConstants.savedCurrentServerIdKey, server.id);
    await secureStorage.delete(AppConstants.savedSidKey);
    await secureStorage.delete(AppConstants.savedSynoTokenKey);
    await secureStorage.delete(AppConstants.savedCookieHeaderKey);
    await secureStorage.delete(AppConstants.savedRequestHashSeedKey);
    await secureStorage.delete(AppConstants.savedAuthTokenKey);
  };
});

final updateServerProvider = Provider<Future<void> Function(NasServer)>((ref) {
  return (server) async {
    final existing = [...ref.read(savedServersProvider)];
    final index = existing.indexWhere((s) => s.id == server.id || s.name == server.name);
    if (index >= 0) {
      existing[index] = server;
      ref.read(savedServersProvider.notifier).state = existing;
      await _persistServers(ref, existing);

      final current = ref.read(currentServerProvider);
      if (current != null && (current.id == existing[index].id || current.name == server.name)) {
        ref.read(currentServerProvider.notifier).state = server;
        final localStorage = ref.read(localStorageProvider);
        await localStorage.writeString(AppConstants.savedCurrentServerIdKey, server.id);
      }
    }
  };
});

final deleteServerProvider = Provider<Future<void> Function(NasServer)>((ref) {
  return (server) async {
    final localStorage = ref.read(localStorageProvider);
    final secureStorage = ref.read(secureStorageProvider);

    final existing = [...ref.read(savedServersProvider)]..removeWhere((s) => s.id == server.id);
    ref.read(savedServersProvider.notifier).state = existing;

    await _persistServers(ref, existing);

    final current = ref.read(currentServerProvider);
    if (current?.id == server.id) {
      ref.read(currentServerProvider.notifier).state = null;
      ref.read(currentSessionProvider.notifier).state = null;
      await localStorage.remove(AppConstants.savedCurrentServerIdKey);
      await secureStorage.delete(AppConstants.savedSidKey);
      await secureStorage.delete(AppConstants.savedSynoTokenKey);
      await secureStorage.delete(AppConstants.savedCookieHeaderKey);
      await secureStorage.delete(AppConstants.savedRequestHashSeedKey);
      await secureStorage.delete(AppConstants.savedAuthTokenKey);
    }
  };
});

final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final server = ref.read(currentServerProvider);
    final session = ref.read(currentSessionProvider);

    if (server != null && session != null) {
      try {
        await ref.read(authRepositoryProvider).logout(server: server, session: session);
      } catch (_) {}
    }

    ref.read(currentServerProvider.notifier).state = null;

    final localStorage = ref.read(localStorageProvider);
    await localStorage.remove(AppConstants.savedCurrentServerIdKey);
    await localStorage.remove(AppConstants.sessionExpiredFlagKey);

    await ref.read(clearSessionProvider)(markExpired: false);
  };
});
