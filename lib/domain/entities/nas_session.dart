class NasSession {
  final String serverId;
  final String sid;
  final String? synoToken;
  final String? cookieHeader;
  final String? requestHashSeed;
  final String? authToken;
  final int requestNonce;

  const NasSession({
    required this.serverId,
    required this.sid,
    this.synoToken,
    this.cookieHeader,
    this.requestHashSeed,
    this.authToken,
    this.requestNonce = 0,
  });

  NasSession copyWith({
    String? serverId,
    String? sid,
    String? synoToken,
    String? cookieHeader,
    String? requestHashSeed,
    String? authToken,
    int? requestNonce,
  }) {
    return NasSession(
      serverId: serverId ?? this.serverId,
      sid: sid ?? this.sid,
      synoToken: synoToken ?? this.synoToken,
      cookieHeader: cookieHeader ?? this.cookieHeader,
      requestHashSeed: requestHashSeed ?? this.requestHashSeed,
      authToken: authToken ?? this.authToken,
      requestNonce: requestNonce ?? this.requestNonce,
    );
  }
}
