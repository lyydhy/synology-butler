class DdnsRecord {
  final String id;
  final String provider;
  final String hostname;
  final String ip;
  final String status;
  final String lastUpdated;

  const DdnsRecord({
    required this.id,
    required this.provider,
    required this.hostname,
    required this.ip,
    required this.status,
    required this.lastUpdated,
  });
}

class ExternalAccessData {
  final List<DdnsRecord> records;
  final String? nextUpdateTime;

  const ExternalAccessData({
    this.records = const [],
    this.nextUpdateTime,
  });
}
