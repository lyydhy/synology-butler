/// 分享链接结果
class ShareLinkResult {
  final String url;
  final String id;
  final String name;
  final String path;
  final String? qrcode;
  final int expireTimes; // 0 = 无限制
  final String? dateExpired; // 过期时间，ISO8601
  final String? dateAvailable; // 生效时间，ISO8601
  final bool enableUpload;
  final bool isFolder;
  final String linkOwner;
  final String status;

  ShareLinkResult({
    required this.url,
    required this.id,
    required this.name,
    required this.path,
    this.qrcode,
    this.expireTimes = 0,
    this.dateExpired,
    this.dateAvailable,
    this.enableUpload = false,
    this.isFolder = false,
    this.linkOwner = '',
    this.status = 'valid',
  });

  factory ShareLinkResult.fromMap(Map<String, dynamic> map) {
    return ShareLinkResult(
      url: map['url'] as String? ?? '',
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      path: map['path'] as String? ?? '',
      qrcode: map['qrcode'] as String?,
      expireTimes: _toIntSafe(map['expire_times']),
      dateExpired: map['date_expired'] as String?,
      dateAvailable: map['date_available'] as String?,
      enableUpload: map['enable_upload'] == true,
      isFolder: map['isFolder'] == true,
      linkOwner: map['link_owner'] as String? ?? '',
      status: map['status'] as String? ?? 'valid',
    );
  }

  static int _toIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  ShareLinkResult copyWith({
    String? url,
    String? id,
    String? name,
    String? path,
    String? qrcode,
    int? expireTimes,
    String? dateExpired,
    String? dateAvailable,
    bool? enableUpload,
    bool? isFolder,
    String? linkOwner,
    String? status,
  }) {
    return ShareLinkResult(
      url: url ?? this.url,
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      qrcode: qrcode ?? this.qrcode,
      expireTimes: expireTimes ?? this.expireTimes,
      dateExpired: dateExpired ?? this.dateExpired,
      dateAvailable: dateAvailable ?? this.dateAvailable,
      enableUpload: enableUpload ?? this.enableUpload,
      isFolder: isFolder ?? this.isFolder,
      linkOwner: linkOwner ?? this.linkOwner,
      status: status ?? this.status,
    );
  }
}
