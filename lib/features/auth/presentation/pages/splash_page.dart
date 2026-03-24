import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/local_app_logger.dart';
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
        child: restoreAsync.when(
          data: (restored) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await LocalAppLogger.log(
                level: 'info',
                module: 'splash',
                event: 'restore_completed',
                extra: {'restored': restored},
              );
              await Future<void>.delayed(const Duration(milliseconds: 1600));
              if (context.mounted) {
                unawaited(LocalAppLogger.log(
                  level: 'info',
                  module: 'splash',
                  event: 'navigate',
                  extra: {'target': restored ? '/home' : '/login'},
                ));
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
              await LocalAppLogger.log(
                level: 'error',
                module: 'splash',
                event: 'restore_failed',
              );
              await Future<void>.delayed(const Duration(milliseconds: 1600));
              if (context.mounted) {
                unawaited(LocalAppLogger.log(
                  level: 'info',
                  module: 'splash',
                  event: 'navigate',
                  extra: {'target': '/login'},
                ));
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

    return SizedBox.expand(
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.dns_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                loadingText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
