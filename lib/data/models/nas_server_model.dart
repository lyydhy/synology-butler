import 'dart:convert';

class NasServerModel {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool https;
  final String? basePath;
  final bool ignoreBadCertificate;

  const NasServerModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.https,
    this.basePath,
    this.ignoreBadCertificate = false,
  });

  String get baseUrl {
    final scheme = https ? 'https' : 'http';
    final path = (basePath == null || basePath!.isEmpty) ? '' : basePath!;
    return '$scheme://$host:$port$path';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'https': https,
        'basePath': basePath,
        'ignoreBadCertificate': ignoreBadCertificate,
      };

  factory NasServerModel.fromJson(Map<String, dynamic> json) => NasServerModel(
        id: json['id'].toString(),
        name: json['name'].toString(),
        host: json['host'].toString(),
        port: (json['port'] as num).toInt(),
        https: json['https'] == true,
        basePath: json['basePath']?.toString(),
        ignoreBadCertificate: json['ignoreBadCertificate'] == true,
      );

  String encode() => jsonEncode(toJson());

  factory NasServerModel.decode(String value) => NasServerModel.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
