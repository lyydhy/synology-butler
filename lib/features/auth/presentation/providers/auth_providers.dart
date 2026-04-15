import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../packages/presentation/providers/package_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_realtime_global.dart';

import 'current_connection_readers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../core/network/realtime_reconnect_bridge.dart';
import '../../../../core/network/session_recovery_bridge.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/server_mapper.dart';
import '../../../../data/api/dsm_auth_api.dart';
import '../../../../data/models/nas_server_model.dart';
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../../domain/entities/nas_server.dart';
import '../../../../domain/entities/nas_session.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_realtime_global.dart';
import '../../../information_center/presentation/providers/information_center_providers.dart';
import '../../../packages/presentation/providers/package_providers.dart';

final authApiProvider = Provider((ref) => DsmAuthApi());
final localStorageProvider = Provider((ref) => LocalStorageService());
final secureStorageProvider = Provider((ref) => const SecureStorageService(FlutterSecureStorage()));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authApiProvider));
});

final savedServersProvider = StateProvider<List<NasServer>>((ref) => []);
final savedUsernameProvider = StateProvider<String?>((ref) => null);
final savedPasswordProvider = StateProvider<String?>((ref) => null);
final savedRememberPasswordProvider = StateProvider<bool>((ref) => false);
final savedServerUsernamesProvider = StateProvider<Map<String, String>>((ref) => {});
final savedServerLastUsedProvider = StateProvider<Map<String, int>>((ref) => {});

Future<void> _persistServers(Ref ref, List<NasServer> servers) async {
  final localStorage = ref.read(localStorageProvider);
  final encoded = servers.map((s) => ServerMapper.toModel(s).encode()).toList();
  await localStorage.writeStringList(AppConstants.savedServersKey, encoded);
}

Future<void> _persistServerUsernames(Ref ref, Map<String, String> usernames) async {
  await ref.read(localStorageProvider).writeJsonMap(AppConstants.savedServerUsernamesKey, usernames);
}

Future<void> _persistServerLastUsed(Ref ref, Map<String, int> values) async {
  await ref.read(localStorageProvider).writeJsonMap(AppConstants.savedServerLastUsedKey, values);
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
  final savedRememberPassword = await localStorage.readString(AppConstants.savedRememberPasswordKey);
  final savedPassword = currentServerId == null ? null : await secureStorage.read('${AppConstants.savedPasswordPrefix}$currentServerId');
  final savedServerUsernamesRaw = await localStorage.readJsonMap(AppConstants.savedServerUsernamesKey);
  final savedServerLastUsedRaw = await localStorage.readJsonMap(AppConstants.savedServerLastUsedKey);

  final savedServerUsernames = savedServerUsernamesRaw.map(
    (key, value) => MapEntry(key, value.toString()),
  );
  final savedServerLastUsed = savedServerLastUsedRaw.map(
    (key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0),
  );

  ref.read(savedUsernameProvider.notifier).state = savedUsername;
  ref.read(savedPasswordProvider.notifier).state = savedPassword;
  ref.read(savedRememberPasswordProvider.notifier).state = savedRememberPassword == '1';
  ref.read(savedServerUsernamesProvider.notifier).state = savedServerUsernames;
  ref.read(savedServerLastUsedProvider.notifier).state = savedServerLastUsed;

  final servers = savedServers.map(NasServerModel.decode).map(ServerMapper.toEntity).toList();
  ref.read(savedServersProvider.notifier).state = servers;

  ref.read(currentConnectionStoreProvider);

  if (currentServerId == null || savedSid == null || savedSid.isEmpty) {
    return false;
  }

  final matched = servers.where((s) => s.id == currentServerId);
  if (matched.isEmpty) {
    return false;
  }
  final currentServer = matched.first;

  setConnection(
    server: currentServer,
    session: NasSession(
      serverId: currentServer.id,
      sid: savedSid,
      synoToken: savedSynoToken,
      cookieHeader: savedCookieHeader,
      requestHashSeed: savedRequestHashSeed,
      authToken: savedAuthToken,
    ),
  );

  // Re-login successful — invalidate cached data so it re-fetches from new session
  ref.invalidate(installedPackagesProvider);
  ref.invalidate(globalRealtimeOverviewProvider);

  return true;
});

final clearSessionProvider = Provider<Future<void> Function({bool markExpired})>((ref) {
  return ({bool markExpired = false}) async {
    clearSession();

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

Future<void> _persistSessionSecrets(Ref ref, NasSession session) async {
  final secureStorage = ref.read(secureStorageProvider);
  await secureStorage.write(AppConstants.savedSidKey, session.sid);

  if (session.synoToken != null && session.synoToken!.isNotEmpty) {
    await secureStorage.write(AppConstants.savedSynoTokenKey, session.synoToken!);
  } else {
    await secureStorage.delete(AppConstants.savedSynoTokenKey);
  }
  if (session.cookieHeader != null && session.cookieHeader!.isNotEmpty) {
    await secureStorage.write(AppConstants.savedCookieHeaderKey, session.cookieHeader!);
  } else {
    await secureStorage.delete(AppConstants.savedCookieHeaderKey);
  }
  if (session.requestHashSeed != null && session.requestHashSeed!.isNotEmpty) {
    await secureStorage.write(AppConstants.savedRequestHashSeedKey, session.requestHashSeed!);
  } else {
    await secureStorage.delete(AppConstants.savedRequestHashSeedKey);
  }
  if (session.authToken != null && session.authToken!.isNotEmpty) {
    await secureStorage.write(AppConstants.savedAuthTokenKey, session.authToken!);
  } else {
    await secureStorage.delete(AppConstants.savedAuthTokenKey);
  }
}

final persistLoginProvider = Provider<Future<void> Function(NasServer, NasSession, String, {String? password, required bool rememberPassword})>((ref) {
  return (server, session, username, {String? password, required bool rememberPassword}) async {
    // Keep memory store in sync with storage — prevents stale state on hot-reload
    setConnection(server: server, session: session);

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
    ref.read(savedRememberPasswordProvider.notifier).state = rememberPassword;
    ref.read(savedPasswordProvider.notifier).state = rememberPassword ? password : null;

    // Persist in connectionStore for hot-reload-safe session recovery
    if (rememberPassword && password != null && password.isNotEmpty) {
      connectionStore.setCredentials(username: username, password: password);
    } else {
      connectionStore.clearCredentials();
    }

    final usernameMap = {...ref.read(savedServerUsernamesProvider)};
    usernameMap[server.id] = username;
    ref.read(savedServerUsernamesProvider.notifier).state = usernameMap;

    final lastUsedMap = {...ref.read(savedServerLastUsedProvider)};
    lastUsedMap[server.id] = DateTime.now().millisecondsSinceEpoch;
    ref.read(savedServerLastUsedProvider.notifier).state = lastUsedMap;

    await _persistServers(ref, existing);
    await _persistServerUsernames(ref, usernameMap);
    await _persistServerLastUsed(ref, lastUsedMap);
    await localStorage.writeString(AppConstants.savedCurrentServerIdKey, server.id);
    await localStorage.writeString(AppConstants.savedUsernameKey, username);
    await localStorage.writeString(AppConstants.savedRememberPasswordKey, rememberPassword ? '1' : '0');
    if ( password != null && password.isNotEmpty) {
      await secureStorage.write('${AppConstants.savedPasswordPrefix}${server.id}', password);
    } else {
      await secureStorage.delete('${AppConstants.savedPasswordPrefix}${server.id}');
    }
    await localStorage.remove(AppConstants.sessionExpiredFlagKey);
    await _persistSessionSecrets(ref, session);
  };
});

Future<NasSession>? _recoverSessionInFlight;

final recoverSessionProvider = Provider<Future<NasSession> Function()>((ref) {
  Future<NasSession> recover() {
    return _recoverSessionInFlight ??= (() async {
      final server = connectionStore.server;
      // Read credentials from connectionStore first (survives hot-reload).
      // Fall back to Riverpod providers in case this is a cold start.
      final stored = connectionStore.credentials;
      final username = stored?.username ?? ref.read(savedUsernameProvider);
      final password = stored?.password ?? ref.read(savedPasswordProvider);

      if (server == null) {
        throw Exception('No active NAS server to recover session');
      }
      if (username == null || username.isEmpty || password == null || password.isEmpty) {
        throw Exception('Missing saved credential for automatic re-login');
      }

      final recovered = await ref.read(authRepositoryProvider).login(
            server: server,
            username: username,
            password: password,
          );

      setSession(recovered);
      await _persistSessionSecrets(ref, recovered);
      await ref.read(localStorageProvider).remove(AppConstants.sessionExpiredFlagKey);
      final sidPreview = recovered.sid.length > 8 ? recovered.sid.substring(0, 8) : recovered.sid;
      final synoTokenPreview = recovered.synoToken == null || recovered.synoToken!.isEmpty
          ? 'missing'
          : (recovered.synoToken!.length > 8 ? recovered.synoToken!.substring(0, 8) : recovered.synoToken!);
      // ignore: avoid_print
      print('[Auth][Recover] session refreshed, trigger realtime reconnect sid=$sidPreview token=$synoTokenPreview');
      await RealtimeReconnectBridge.callback?.call();
      return recovered;
    })().whenComplete(() {
      _recoverSessionInFlight = null;
    });
  }

  SessionRecoveryBridge.callback = () async {
    final session = await recover();
    return {
      'sid': session.sid,
      'synoToken': session.synoToken,
      'cookieHeader': session.cookieHeader,
    };
  };

  return recover;
});

final refreshSynoTokenProvider = Provider<Future<NasSession> Function()>((ref) {
  return () => ref.read(recoverSessionProvider)();
});

final refreshRealtimeSessionProvider = Provider<Future<NasSession> Function()>((ref) {
  return () => ref.read(recoverSessionProvider)();
});

final switchCurrentServerProvider = Provider<Future<void> Function(NasServer)>((ref) {
  return (server) async {
    setServer(server);
    clearSession();

    // 重置所有业务状态
    ref.invalidate(dashboardBaseOverviewProvider);
    ref.invalidate(globalRealtimeOverviewProvider);
    ref.invalidate(informationCenterProvider);
    ref.invalidate(installedPackagesProvider);
    ref.invalidate(dockerFeatureInstalledProvider);

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
      final oldServerId = existing[index].id;
      existing[index] = server;
      ref.read(savedServersProvider.notifier).state = existing;
      await _persistServers(ref, existing);

      if (oldServerId != server.id) {
        final usernames = {...ref.read(savedServerUsernamesProvider)};
        final lastUsed = {...ref.read(savedServerLastUsedProvider)};

        if (usernames.containsKey(oldServerId)) {
          usernames[server.id] = usernames.remove(oldServerId)!;
        }
        if (lastUsed.containsKey(oldServerId)) {
          lastUsed[server.id] = lastUsed.remove(oldServerId)!;
        }

        ref.read(savedServerUsernamesProvider.notifier).state = usernames;
        ref.read(savedServerLastUsedProvider.notifier).state = lastUsed;
        await _persistServerUsernames(ref, usernames);
        await _persistServerLastUsed(ref, lastUsed);
      }

      final current = connectionStore.server;
      if (current != null && (current.id == oldServerId || current.name == server.name)) {
        setServer(server);
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

    final usernames = {...ref.read(savedServerUsernamesProvider)}..remove(server.id);
    final lastUsed = {...ref.read(savedServerLastUsedProvider)}..remove(server.id);
    ref.read(savedServerUsernamesProvider.notifier).state = usernames;
    ref.read(savedServerLastUsedProvider.notifier).state = lastUsed;
    await _persistServerUsernames(ref, usernames);
    await _persistServerLastUsed(ref, lastUsed);

    final current = connectionStore.server;
    if (current?.id == server.id) {
      clearAll();
      clearSession();
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
    final server = connectionStore.server;
    final session = connectionStore.session;

    if (server != null && session != null) {
      try {
        await ref.read(authRepositoryProvider).logout(server: server, session: session).timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {
        // Network errors are handled by UnreachableRedirectInterceptor.
        // For logout, we just need to ensure local state is cleared even if
        // the server cannot be reached.
      }
    }

    clearAll();

    final localStorage = ref.read(localStorageProvider);
    await localStorage.remove(AppConstants.savedCurrentServerIdKey);
    await localStorage.remove(AppConstants.sessionExpiredFlagKey);

    await ref.read(clearSessionProvider)(markExpired: false);
  };
});
