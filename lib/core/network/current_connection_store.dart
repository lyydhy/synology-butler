import '../../domain/entities/nas_server.dart';
import '../../domain/entities/nas_session.dart';

class CurrentConnectionStore {
  CurrentConnectionStore._();

  static final CurrentConnectionStore instance = CurrentConnectionStore._();

  NasServer? _server;
  NasSession? _session;

  NasServer? get server => _server;
  NasSession? get session => _session;

  bool get hasConnection => _server != null && _session != null;

  void setServer(NasServer? server) {
    _server = server;
  }

  void setSession(NasSession? session) {
    _session = session;
  }

  void setConnection({
    required NasServer server,
    required NasSession session,
  }) {
    _server = server;
    _session = session;
  }

  void clearSession() {
    _session = null;
  }

  void clearAll() {
    _server = null;
    _session = null;
  }
}
