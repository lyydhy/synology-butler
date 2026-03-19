class NasSession {
  final String serverId;
  final String sid;
  final String? synoToken;
  final String? cookieHeader;

  const NasSession({
    required this.serverId,
    required this.sid,
    this.synoToken,
    this.cookieHeader,
  });
}
