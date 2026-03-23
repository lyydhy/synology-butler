import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final restoreAsync = ref.watch(restoreSessionProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: restoreAsync.when(
            data: (restored) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Future<void>.delayed(const Duration(milliseconds: 700));
                if (context.mounted) {
                  context.go(restored ? '/home' : '/login');
                }
              });
              return const _SplashContent(
                title: '群晖管家',
                subtitle: '正在恢复你的连接与设备状态',
                loadingText: '正在进入...',
              );
            },
            error: (_, __) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Future<void>.delayed(const Duration(milliseconds: 700));
                if (context.mounted) {
                  context.go('/login');
                }
              });
              return const _SplashContent(
                title: '群晖管家',
                subtitle: '正在准备登录界面',
                loadingText: '正在跳转登录...',
              );
            },
            loading: () => const _SplashContent(
              title: '群晖管家',
              subtitle: '你的 DSM 7+ 掌上助手',
              loadingText: '正在启动...',
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.title,
    required this.subtitle,
    required this.loadingText,
  });

  final String title;
  final String subtitle;
  final String loadingText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.dns_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            loadingText,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
