import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/local_app_logger.dart';
import '../../../external_share/services/external_share_pending_store.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  Future<String> _resolveTarget(bool restored) async {
    const pendingStore = ExternalSharePendingStore();
    final pending = await pendingStore.load();
    if (pending != null) {
      return restored ? '/external-upload' : '/login';
    }
    return restored ? '/home' : '/login';
  }

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
              final target = await _resolveTarget(restored);
              await LocalAppLogger.log(
                level: 'info',
                module: 'splash',
                event: 'restore_completed',
                extra: {'restored': restored, 'target': target},
              );
              await Future<void>.delayed(const Duration(milliseconds: 1600));
              if (!context.mounted) return;
              final router = GoRouter.of(context);

              if (target == '/external-upload') {
                final pending = await const ExternalSharePendingStore().load();
                if (!context.mounted) return;
                if (pending != null) {
                  await const ExternalSharePendingStore().clear();
                  if (!context.mounted) return;
                  router.push('/external-upload', extra: pending);
                  return;
                }
              }

              unawaited(LocalAppLogger.log(
                level: 'info',
                module: 'splash',
                event: 'navigate',
                extra: {'target': target},
              ));
              router.go(target);
            });
            return const _SplashContent(
              title: null,
              subtitle: null,
              loadingText: null,
              restoring: true,
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
              title: null,
              subtitle: null,
              loadingText: null,
              restoring: false,
            );
          },
          loading: () => const _SplashContent(
            title: null,
            subtitle: null,
            loadingText: null,
            restoring: false,
            initial: true,
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    this.title,
    this.subtitle,
    this.loadingText,
    this.restoring = false,
    this.initial = false,
  });

  final String? title;
  final String? subtitle;
  final String? loadingText;
  final bool restoring;
  final bool initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = title ?? l10n.splashTitle;
    final displaySubtitle = subtitle ?? (initial ? l10n.splashSubtitleReady : (restoring ? l10n.splashSubtitleRestoring : l10n.splashSubtitlePreparing));
    final displayLoadingText = loadingText ?? (initial ? l10n.splashLoadingStart : (restoring ? l10n.splashLoadingEnter : l10n.splashLoadingLogin));

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
                displayTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  displaySubtitle,
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
                displayLoadingText,
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
