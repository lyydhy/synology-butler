/// 网络状态模型
class NetworkModel {
  /// 常规网络信息
  final NetworkGeneral? general;

  /// 网络接口列表（以太网）
  final List<NetworkInterface> ethernets;

  /// PPPoE 接口列表
  final List<NetworkInterface> pppoes;

  /// 代理设置
  final ProxySettings? proxy;

  /// 网关信息
  final GatewayInfo? gateway;

  const NetworkModel({
    this.general,
    this.ethernets = const [],
    this.pppoes = const [],
    this.proxy,
    this.gateway,
  });

  factory NetworkModel.fromApiResponse(List<dynamic> results) {
    NetworkGeneral? general;
    List<NetworkInterface> ethernets = [];
    List<NetworkInterface> pppoes = [];
    ProxySettings? proxy;
    GatewayInfo? gateway;

    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      if (item['success'] != true) continue;

      final api = item['api'] as String?;
      final data = item['data'] as Map<String, dynamic>?;

      if (data == null) continue;

      switch (api) {
        case 'SYNO.Core.Network':
          general = NetworkGeneral.fromJson(data);
          break;
        case 'SYNO.Core.Network.Ethernet':
          if (data['ethernets'] is List) {
            ethernets = (data['ethernets'] as List)
                .map((e) => NetworkInterface.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          break;
        case 'SYNO.Core.Network.PPPoE':
          if (data['pppoes'] is List) {
            pppoes = (data['pppoes'] as List)
                .map((e) => NetworkInterface.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          break;
        case 'SYNO.Core.Network.Proxy':
          proxy = ProxySettings.fromJson(data);
          break;
        case 'SYNO.Core.Network.Router.Gateway.List':
          gateway = GatewayInfo.fromJson(data);
          break;
      }
    }

    return NetworkModel(
      general: general,
      ethernets: ethernets,
      pppoes: pppoes,
      proxy: proxy,
      gateway: gateway,
    );
  }
}

/// 常规网络信息
class NetworkGeneral {
  final String serverName;
  final String? gateway;
  final String? v6gateway;
  final bool dnsManual;
  final String? dnsPrimary;
  final String? dnsSecondary;
  final String? workgroup;

  const NetworkGeneral({
    required this.serverName,
    this.gateway,
    this.v6gateway,
    this.dnsManual = false,
    this.dnsPrimary,
    this.dnsSecondary,
    this.workgroup,
  });

  factory NetworkGeneral.fromJson(Map<String, dynamic> json) {
    return NetworkGeneral(
      serverName: json['server_name'] as String? ?? '',
      gateway: json['gateway'] as String?,
      v6gateway: json['v6gateway'] as String?,
      dnsManual: json['dns_manual'] as bool? ?? false,
      dnsPrimary: json['dns_primary'] as String?,
      dnsSecondary: json['dns_secondary'] as String?,
      workgroup: json['workgroup'] as String?,
    );
  }
}

/// 网络接口（以太网或 PPPoE）
class NetworkInterface {
  final String id;
  final String displayName;
  final String status; // connected, disconnected, etc.
  final bool useDhcp;
  final String? ip;
  final String? mask;
  final List<String> ipv6;
  final int? mtu;
  final int? maxSupportedSpeed;
  final bool duplex;
  final String? mac;

  const NetworkInterface({
    required this.id,
    required this.displayName,
    required this.status,
    this.useDhcp = false,
    this.ip,
    this.mask,
    this.ipv6 = const [],
    this.mtu,
    this.maxSupportedSpeed,
    this.duplex = true,
    this.mac,
  });

  factory NetworkInterface.fromJson(Map<String, dynamic> json) {
    List<String> ipv6List = [];
    if (json['ipv6'] is List) {
      ipv6List = (json['ipv6'] as List).map((e) => e.toString()).toList();
    }

    return NetworkInterface(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name'] as String? ?? json['ifname'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      useDhcp: json['use_dhcp'] as bool? ?? false,
      ip: json['ip'] as String?,
      mask: json['mask'] as String?,
      ipv6: ipv6List,
      mtu: json['mtu'] as int?,
      maxSupportedSpeed: json['max_supported_speed'] as int?,
      duplex: json['duplex'] as bool? ?? true,
      mac: json['mac'] as String?,
    );
  }

  bool get isConnected => status == 'connected';

  String get speedDisplay {
    if (maxSupportedSpeed == null) return '';
    return '$maxSupportedSpeed Mb/s';
  }

  String get duplexDisplay => duplex ? '全双工' : '半双工';
}

/// 代理设置
class ProxySettings {
  final bool enable;
  final String? httpHost;
  final String? httpPort;
  final String? httpsHost;
  final String? httpsPort;
  final String? ftpHost;
  final String? ftpPort;

  const ProxySettings({
    this.enable = false,
    this.httpHost,
    this.httpPort,
    this.httpsHost,
    this.httpsPort,
    this.ftpHost,
    this.ftpPort,
  });

  factory ProxySettings.fromJson(Map<String, dynamic> json) {
    return ProxySettings(
      enable: json['enable'] as bool? ?? false,
      httpHost: json['http_host'] as String?,
      httpPort: json['http_port']?.toString(),
      httpsHost: json['https_host'] as String?,
      httpsPort: json['https_port']?.toString(),
      ftpHost: json['ftp_host'] as String?,
      ftpPort: json['ftp_port']?.toString(),
    );
  }
}

/// 网关信息
class GatewayInfo {
  final List<GatewayRoute> routes;

  const GatewayInfo({
    this.routes = const [],
  });

  factory GatewayInfo.fromJson(Map<String, dynamic> json) {
    List<GatewayRoute> routesList = [];
    if (json['routes'] is List) {
      routesList = (json['routes'] as List)
          .map((e) => GatewayRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return GatewayInfo(routes: routesList);
  }
}

/// 网关路由
class GatewayRoute {
  final String? gateway;
  final String? interfaceName;
  final String? type;

  const GatewayRoute({
    this.gateway,
    this.interfaceName,
    this.type,
  });

  factory GatewayRoute.fromJson(Map<String, dynamic> json) {
    return GatewayRoute(
      gateway: json['gateway'] as String?,
      interfaceName: json['ifname'] as String?,
      type: json['type'] as String?,
    );
  }
}
