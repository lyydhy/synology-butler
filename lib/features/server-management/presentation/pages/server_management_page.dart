import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../widgets/server_edit_dialog.dart';
import '../widgets/server_management_tile.dart';

class ServerManagementPage extends ConsumerWidget {
  const ServerManagementPage({super.key});

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteDevice),
            content: Text('确定要删除设备“$name”吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteConfirm)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _editServer(BuildContext context, WidgetRef ref, dynamic server) async {
    final l10n = AppLocalizations.of(context);
    final updated = await showDialog(
      context: context,
      builder: (context) => ServerEditDialog(server: server),
    );

    if (updated == null) return;

    await ref.read(updateServerProvider)(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deviceUpdated)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servers = ref.watch(savedServersProvider);
    final currentServer = ref.watch(activeServerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.serverManagement)),
      body: servers.isEmpty
          ? Center(child: Text(l10n.notAvailableYet))
          : ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                return ServerManagementTile(
                  server: server,
                  isCurrent: currentServer?.id == server.id,
                  onSelect: () async {
                    await ref.read(switchCurrentServerProvider)(server);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.switchDeviceRelogin)),
                      );
                      context.go('/login');
                    }
                  },
                  onEdit: () => _editServer(context, ref, server),
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context, server.name);
                    if (!confirmed) return;
                    await ref.read(deleteServerProvider)(server);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.deviceDeleted)),
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/login'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
