class NasSession {
  final String serverId;
  final String sid;
  final String? synoToken;

  const NasSession({
    required this.serverId,
    required this.sid,
    this.synoToken,
  });
}
