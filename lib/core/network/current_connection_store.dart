import 'package:flutter/foundation.dart';

import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';

class CurrentConnectionStore extends ChangeNotifier {
  CurrentConnectionStore._();

  static final CurrentConnectionStore instance = CurrentConnectionStore._();

  NasServer? _server;
  NasSession? _session;

  NasServer? get server => _server;
  NasSession? get session => _session;

  bool get hasConnection => _server != null && _session != null;

  void setServer(NasServer? server) {
    _server = server;
    notifyListeners();
  }

  void setSession(NasSession? session) {
    _session = session;
    notifyListeners();
  }

  void setConnection({
    required NasServer server,
    required NasSession session,
  }) {
    _server = server;
    _session = session;
    notifyListeners();
  }

  void clearSession() {
    _session = null;
    notifyListeners();
  }

  void clearAll() {
    _server = null;
    _session = null;
    _credentials = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  //  Saved credentials (for session auto-recovery)
  // ─────────────────────────────────────────────────────────────

  AuthCredentials? _credentials;

  AuthCredentials? get credentials => _credentials;

  void setCredentials({required String username, required String password}) {
    _credentials = AuthCredentials(username: username, password: password);
  }

  void clearCredentials() {
    _credentials = null;
  }
}

/// Lightweight credential store used only by the session-recovery callback.
/// Not persisted — kept in-memory so hot-reload does not wipe it.
class AuthCredentials {
  const AuthCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

/// Back-reference to the singleton instance for use in interceptors.
final CurrentConnectionStore connectionStore = CurrentConnectionStore.instance;
