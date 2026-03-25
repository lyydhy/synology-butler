typedef RealtimeReconnectCallback = Future<void> Function();

class RealtimeReconnectBridge {
  RealtimeReconnectBridge._();

  static RealtimeReconnectCallback? callback;
}
