import 'package:flutter/material.dart';

import '../../../../domain/entities/nas_server.dart';
import '../../../../core/utils/server_url_helper.dart';

class ServerManagementTile extends StatelessWidget {
  const ServerManagementTile({
    super.key,
    required this.server,
    required this.isCurrent,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final NasServer server;
  final bool isCurrent;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final schemeLabel = server.https ? 'HTTPS' : 'HTTP';
    final pathLabel = (server.basePath == null || server.basePath!.isEmpty) ? '默认路径' : server.basePath!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(isCurrent ? Icons.dns_outlined : Icons.storage_outlined),
        title: Text(server.name),
        subtitle: Text('${ServerUrlHelper.buildBaseUrl(server)}\n$schemeLabel · $pathLabel'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('当前'),
              ),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        onTap: onSelect,
      ),
    );
  }
}
