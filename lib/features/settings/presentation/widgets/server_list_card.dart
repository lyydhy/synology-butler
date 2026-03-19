import 'package:flutter/material.dart';

import '../../../../domain/entities/nas_server.dart';
import '../../../../core/utils/server_url_helper.dart';

class ServerListCard extends StatelessWidget {
  const ServerListCard({
    super.key,
    required this.servers,
    required this.currentServerId,
    required this.onSelect,
  });

  final List<NasServer> servers;
  final String? currentServerId;
  final ValueChanged<NasServer> onSelect;

  @override
  Widget build(BuildContext context) {
    if (servers.isEmpty) {
      return const ListTile(
        title: Text('暂无已保存设备'),
        subtitle: Text('登录过的 NAS 会显示在这里'),
      );
    }

    return Column(
      children: servers
          .map(
            (server) => ListTile(
              leading: Icon(
                server.id == currentServerId ? Icons.dns_outlined : Icons.storage_outlined,
              ),
              title: Text(server.name),
              subtitle: Text(ServerUrlHelper.buildBaseUrl(server)),
              trailing: server.id == currentServerId ? const Text('当前') : null,
              onTap: () => onSelect(server),
            ),
          )
          .toList(),
    );
  }
}
