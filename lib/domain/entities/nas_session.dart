class NasSession {
  const NasSession({
    required this.serverId,
    required this.sid,
    this.synoToken,
    this.cookieHeader,
    this.requestHashSeed,
    this.authToken,
    this.requestNonce = 0,
    /// Stored credentials for automatic session recovery.
    /// Only present when "remember password" was enabled at login time.
    this.username,
    this.password,
  });

  final String serverId;
  final String sid;
  final String? synoToken;
  final String? cookieHeader;
  final String? requestHashSeed;
  final String? authToken;
  final int requestNonce;

  /// Username for automatic re-login after session expiry.
  final String? username;

  /// Password for automatic re-login after session expiry.
  /// Stored encrypted via FlutterSecureStorage at login time.
  final String? password;

  NasSession copyWith({
    String? serverId,
    String? sid,
    String? synoToken,
    String? cookieHeader,
    String? requestHashSeed,
    String? authToken,
    int? requestNonce,
    String? username,
    String? password,
  }) {
    return NasSession(
      serverId: serverId ?? this.serverId,
      sid: sid ?? this.sid,
      synoToken: synoToken ?? this.synoToken,
      cookieHeader: cookieHeader ?? this.cookieHeader,
      requestHashSeed: requestHashSeed ?? this.requestHashSeed,
      authToken: authToken ?? this.authToken,
      requestNonce: requestNonce ?? this.requestNonce,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  bool get canAutoRecover => username != null && username!.isNotEmpty && password != null && password!.isNotEmpty;
}
