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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final servers = ref.watch(savedServersProvider);
    final currentServer = ref.watch(currentConnectionProvider).server;
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);

    final sortedServers = [...servers]
      ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.historyDevices, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: servers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(Icons.dns_outlined, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.noSavedDevices,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addDeviceHint,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: sortedServers.length,
              itemBuilder: (context, index) {
                final server = sortedServers[index];
                final username = savedServerUsernames[server.id];
                final isCurrent = currentServer?.id == server.id;
                final lastUsed = _formatLastUsed(savedServerLastUsed[server.id], l10n);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryServerCard(
                    name: server.name,
                    host: server.host,
                    port: server.port,
                    https: server.https,
                    username: username,
                    lastUsed: lastUsed,
                    isCurrent: isCurrent,
                    theme: theme,
                    onTap: () async {
                      final savedPassword = ref.read(currentConnectionProvider).password;
                      if (username == null || username.isEmpty || savedPassword == null || savedPassword.isEmpty) {
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
                              username: username,
                              password: savedPassword,
                            );
                        setSession(session);
                        await ref.read(persistLoginProvider)(
                          server,
                          session,
                          username,
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
                    onDelete: () async {
                      final confirmed = await _confirmDelete(context, server.name);
                      if (!confirmed) return;
                      await ref.read(deleteServerProvider)(server);
                      if (context.mounted) Toast.success(l10n.deviceDeleted);
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatLastUsed(int? ms, AppLocalizations l10n) {
    if (ms == null || ms <= 0) return '';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return l10n.justUsed;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 30) return l10n.daysAgo(diff.inDays);
    return l10n.usedEarlier;
  }
}

// ─── 历史设备卡片 ────────────────────────────────────────────────
class _HistoryServerCard extends StatelessWidget {
  final String name;
  final String host;
  final int port;
  final bool https;
  final String? username;
  final String lastUsed;
  final bool isCurrent;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryServerCard({
    required this.name,
    required this.host,
    required this.port,
    required this.https,
    required this.username,
    required this.lastUsed,
    required this.isCurrent,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  String get _initials {
    final v = name.trim();
    return v.isEmpty ? 'N' : v.characters.first.toUpperCase();
  }

  String get _displayAddress {
    final showPort = (https && port != 443) || (!https && port != 80);
    return showPort ? '$host:$port' : host;
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrent
                ? primary.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent ? primary.withValues(alpha: 0.30) : theme.dividerColor.withValues(alpha: 0.10),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            // 头像
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCurrent ? primary.withValues(alpha: 0.15) : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: TextStyle(
                  color: isCurrent ? primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 信息
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isCurrent ? primary : null),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '当前',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(
                  _displayAddress,
                  style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
                if ((username ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [username ?? '', lastUsed].where((e) => e.isNotEmpty).join(' · '),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ]),
            ),
            // 删除按钮
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error.withValues(alpha: 0.7)),
              tooltip: '删除',
            ),
          ]),
        ),
      ),
    );
  }
}
