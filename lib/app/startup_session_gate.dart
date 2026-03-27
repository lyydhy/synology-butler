import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/secure_storage_service.dart';

class StartupSessionGateResult {
  const StartupSessionGateResult({
    required this.hasUsableSession,
    required this.initialLocation,
  });

  final bool hasUsableSession;
  final String initialLocation;
}

class StartupSessionGate {
  StartupSessionGate({
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
  })  : _localStorage = localStorage ?? LocalStorageService(),
        _secureStorage = secureStorage ?? const SecureStorageService(FlutterSecureStorage());

  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  Future<StartupSessionGateResult> resolve() async {
    final currentServerId = await _localStorage.readString(AppConstants.savedCurrentServerIdKey);
    final savedSid = await _secureStorage.read(AppConstants.savedSidKey);

    final hasUsableSession =
        currentServerId != null && currentServerId.isNotEmpty && savedSid != null && savedSid.isNotEmpty;

    return StartupSessionGateResult(
      hasUsableSession: hasUsableSession,
      initialLocation: hasUsableSession ? '/home' : '/splash',
    );
  }
}
