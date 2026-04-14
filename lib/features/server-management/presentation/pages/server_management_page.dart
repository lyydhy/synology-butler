import 'dart:ui';
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
import '../../../preferences/providers/preferences_providers.dart';

class ServerManagementPage extends ConsumerStatefulWidget {
  const ServerManagementPage({super.key});

  @override
  ConsumerState<ServerManagementPage> createState() => _ServerManagementPageState();
}

class _ServerManagementPageState extends ConsumerState<ServerManagementPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _doQuickLogin(BuildContext context, dynamic server, String? username) async {
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

  Future<void> _confirmAndDelete(BuildContext context, dynamic server, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(l10n.deleteDevice),
            content: Text(l10n.confirmDeleteDevice(server.name)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.deleteConfirm, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(deleteServerProvider)(server);
    if (context.mounted) Toast.success(l10n.deviceDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final themeColorOption = ref.watch(themeColorProvider);
    final primaryColor = seedColorFor(themeColorOption);
    final servers = ref.watch(savedServersProvider);
    final currentServer = ref.watch(currentConnectionProvider).server;
    final savedServerUsernames = ref.watch(savedServerUsernamesProvider);
    final savedServerLastUsed = ref.watch(savedServerLastUsedProvider);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? HSLColor.fromColor(primaryColor).withLightness(0.06).toColor()
        : HSLColor.fromColor(primaryColor).withLightness(0.93).withSaturation(0.25).toColor();

    final sortedServers = [...servers]
      ..sort((a, b) => (savedServerLastUsed[b.id] ?? 0).compareTo(savedServerLastUsed[a.id] ?? 0));

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [
        // 背景装饰
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.12),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.08),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // 主内容
        FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // 毛玻璃 AppBar
              SliverAppBar(
                backgroundColor: isDark
                    ? Colors.black.withValues(alpha: 0.60)
                    : Colors.white.withValues(alpha: 0.75),
                expandedHeight: 80,
                floating: true,
                pinned: true,
                snap: false,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
                title: Text(
                  l10n.historyDevices,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              // 设备列表
              if (sortedServers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(theme: theme, l10n: l10n, primaryColor: primaryColor),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final server = sortedServers[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < sortedServers.length - 1 ? 10.0 : 0.0),
                          child: _ServerCard(
                            theme: theme,
                            primaryColor: primaryColor,
                            name: server.name,
                            host: server.host,
                            port: server.port,
                            https: server.https,
                            username: savedServerUsernames[server.id],
                            lastUsedMs: savedServerLastUsed[server.id],
                            isCurrent: currentServer?.id == server.id,
                            l10n: l10n,
                            index: index,
                            onTap: () => _doQuickLogin(context, server, savedServerUsernames[server.id]),
                            onDelete: () => _confirmAndDelete(context, server, l10n),
                          ),
                        );
                      },
                      childCount: sortedServers.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── 空状态 ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;
  final Color primaryColor;

  const _EmptyState({required this.theme, required this.l10n, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.cloud_outlined, size: 48, color: primaryColor.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.noSavedDevices,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.addDeviceHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 服务器卡片 ────────────────────────────────────────────────
class _ServerCard extends StatelessWidget {
  final ThemeData theme;
  final Color primaryColor;
  final String name;
  final String host;
  final int port;
  final bool https;
  final String? username;
  final int? lastUsedMs;
  final bool isCurrent;
  final AppLocalizations l10n;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ServerCard({
    required this.theme,
    required this.primaryColor,
    required this.name,
    required this.host,
    required this.port,
    required this.https,
    required this.username,
    required this.lastUsedMs,
    required this.isCurrent,
    required this.l10n,
    required this.index,
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Dismissible(
        key: Key('$host:$port'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false; // let the dialog handle actual deletion
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 26),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCurrent
                      ? primaryColor.withValues(alpha: 0.35)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: isCurrent ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCurrent ? primaryColor : Colors.black).withValues(alpha: isCurrent ? 0.10 : 0.04),
                    blurRadius: isCurrent ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(children: [
                // 头像
                _buildAvatar(),
                const SizedBox(width: 14),
                // 信息
                Expanded(child: _buildInfo()),
                // 删除
                _buildDeleteButton(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrent
              ? [
                  primaryColor.withValues(alpha: 0.20),
                  primaryColor.withValues(alpha: 0.08),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                ],
        ),
        border: Border.all(
          color: isCurrent ? primaryColor.withValues(alpha: 0.4) : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: isCurrent ? primaryColor : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isCurrent) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              '当前',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
        ],
        const Spacer(),
        // 协议标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: (https ? primaryColor : Colors.orange.shade700).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              https ? Icons.lock_outline : Icons.lock_open_outlined,
              size: 10,
              color: https ? primaryColor : Colors.orange.shade700,
            ),
            const SizedBox(width: 3),
            Text(
              https ? 'HTTPS' : 'HTTP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: https ? primaryColor : Colors.orange.shade700,
              ),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 5),
      Text(
        _address,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      if ((username ?? '').isNotEmpty) ...[
        const SizedBox(height: 3),
        Row(children: [
          Icon(
            Icons.person_outline,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              lastUsedMs != null && lastUsedMs! > 0 ? '$username · ${_timeAgo(lastUsedMs!)}' : username!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.80),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ],
    ]);
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: onDelete,
      icon: Icon(
        Icons.delete_outline_rounded,
        color: theme.colorScheme.error.withValues(alpha: 0.55),
      ),
      tooltip: l10n.deleteDevice,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
