class DdnsRecordModel {
  final String id;
  final String provider;
  final String hostname;
  final String ip;
  final String status;
  final String lastUpdated;

  const DdnsRecordModel({
    required this.id,
    required this.provider,
    required this.hostname,
    required this.ip,
    required this.status,
    required this.lastUpdated,
  });
}

class ExternalAccessModel {
  final List<DdnsRecordModel> records;
  final String? nextUpdateTime;

  const ExternalAccessModel({
    this.records = const [],
    this.nextUpdateTime,
  });
}
