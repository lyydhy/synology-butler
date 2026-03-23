class NasServer {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool https;
  final String? basePath;
  final bool ignoreBadCertificate;

  const NasServer({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.https,
    this.basePath,
    this.ignoreBadCertificate = false,
  });
}
