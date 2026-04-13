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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(l10n.historyDevices, style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
      ),
      body: servers.isEmpty
          ? _EmptyState(theme: theme, l10n: l10n)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: sortedServers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final server = sortedServers[index];
                return _DeviceCard(
                  theme: theme,
                  name: server.name,
                  host: server.host,
                  port: server.port,
                  https: server.https,
                  username: savedServerUsernames[server.id],
                  lastUsedMs: savedServerLastUsed[server.id],
                  isCurrent: currentServer?.id == server.id,
                  l10n: l10n,
                  onTap: () => _doQuickLogin(context, ref, server, savedServerUsernames[server.id]),
                  onDelete: () => _confirmAndDelete(context, ref, server, l10n),
                );
              },
            ),
    );
  }

  Future<void> _doQuickLogin(BuildContext context, WidgetRef ref, dynamic server, String? username) async {
    final savedPassword = ref.read(currentConnectionProvider).password;
    if (username == null || username.isEmpty || savedPassword == null || savedPassword.isEmpty) {
      if (context.mounted) Toast.show('账号或密码数据异常，请到登录页重新输入');
      return;
    }

    await ref.read(switchCurrentServerProvider)(server);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
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
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref, dynamic server, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteDevice),
            content: Text(l10n.confirmDeleteDevice(server.name)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteConfirm)),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(deleteServerProvider)(server);
    if (context.mounted) Toast.success(l10n.deviceDeleted);
  }
}

// ─── 空状态 ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;

  const _EmptyState({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_outlined,
                size: 44,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.noSavedDevices,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.addDeviceHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 设备卡片 ───────────────────────────────────────────────────
class _DeviceCard extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final String host;
  final int port;
  final bool https;
  final String? username;
  final int? lastUsedMs;
  final bool isCurrent;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeviceCard({
    required this.theme,
    required this.name,
    required this.host,
    required this.port,
    required this.https,
    required this.username,
    required this.lastUsedMs,
    required this.isCurrent,
    required this.l10n,
    required this.onTap,
    required this.onDelete,
  });

  String get _initials {
    final v = name.trim();
    return v.isEmpty ? 'N' : v.characters.first.toUpperCase();
  }

  String get _address {
    final showPort = (https && port != 443) || (!https && port != 80);
    return showPort ? '$host:$port' : host;
  }

  String _timeAgo(int ms) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return l10n.justUsed;
    if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 30) return l10n.daysAgo(diff.inDays);
    return l10n.usedEarlier;
  }

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent
                  ? primary.withValues(alpha: 0.25)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            // 头像
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrent
                      ? [primary.withValues(alpha: 0.2), primary.withValues(alpha: 0.08)]
                      : [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surfaceContainerHighest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: TextStyle(
                  color: isCurrent ? primary : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                const SizedBox(height: 4),
                Text(
                  _address,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
                if ((username ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    lastUsedMs != null && lastUsedMs! > 0
                        ? '$username · ${_timeAgo(lastUsedMs!)}'
                        : username!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ]),
            ),
            // 删除
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
              ),
              tooltip: l10n.deleteDevice,
            ),
          ]),
        ),
      ),
    );
  }
}
