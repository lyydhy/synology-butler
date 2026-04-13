import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/toast.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/network/app_dio.dart';
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
            content: Text(l10n.confirmDeleteDevice(name)),
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
      Toast.success(l10n.deviceUpdated);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final servers = ref.watch(savedServersProvider);
    final currentServer = ref.watch(currentConnectionProvider).server;
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.connectionManagement)),
      body: servers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.dns_rounded, size: 34, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.noSavedDevices, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      l10n.addDeviceHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.savedConnections, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        currentServer == null ? l10n.noCurrentDevice : l10n.currentDeviceName(currentServer.name),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      ...servers.map(
                        (server) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ServerManagementTile(
                            server: server,
                            isCurrent: currentServer?.id == server.id,
                            onSelect: () async {
                              final savedUsername = savedServerUsernames[server.id];
                              final savedPassword = ref.read(currentConnectionProvider).password;
                              if (savedUsername == null || savedUsername.isEmpty || savedPassword == null || savedPassword.isEmpty) {
                                if (context.mounted) Toast.show('账号或密码数据异常，请到登录页重新输入');
                                return;
                              }

                              await ref.read(switchCurrentServerProvider)(server);
                              if (!context.mounted) return;
                              Toast.show(l10n.loginInProgress);

                              try {
                                final version = await ref.read(authRepositoryProvider).probeVersion(server: server);
                                if (!version.isDsm7OrAbove) {
                                  if (context.mounted) Toast.show(l10n.dsm6NotSupported(version.displayText));
                                  return;
                                }

                                final session = await ref.read(authRepositoryProvider).login(
                                  server: server,
                                  username: savedUsername,
                                  password: savedPassword,
                                );
                                setSession(session);
                                await ref.read(persistLoginProvider)(
                                  server,
                                  session,
                                  savedUsername,
                                  password: savedPassword,
                                  rememberPassword: true,
                                );
                                if (context.mounted) context.go('/home');
                              } on DioException catch (e) {
                                if (context.mounted) Toast.show(ErrorMapper.map(e).message);
                              } catch (e) {
                                if (context.mounted) Toast.show(ErrorMapper.map(e).message);
                              }
                            },
                            onEdit: () => _editServer(context, ref, server),
                            onDelete: () async {
                              final confirmed = await _confirmDelete(context, server.name);
                              if (!confirmed) return;
                              await ref.read(deleteServerProvider)(server);
                              if (context.mounted) {
                                Toast.success(l10n.deviceDeleted);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
