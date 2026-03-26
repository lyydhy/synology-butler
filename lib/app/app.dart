import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/external_share/models/shared_incoming_file.dart';
import '../features/external_share/services/external_share_pending_store.dart';
import '../features/external_share/services/external_share_service.dart';
import '../features/preferences/providers/preferences_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class QunhuiManagerApp extends ConsumerStatefulWidget {
  const QunhuiManagerApp({super.key});

  @override
  ConsumerState<QunhuiManagerApp> createState() => _QunhuiManagerAppState();
}

class _QunhuiManagerAppState extends ConsumerState<QunhuiManagerApp> {
  StreamSubscription? _externalShareSubscription;
  final ExternalSharePendingStore _pendingStore = const ExternalSharePendingStore();

  @override
  void initState() {
    super.initState();
    _externalShareSubscription = ExternalShareService.instance.watchIncomingFiles().listen((file) async {
      await _handleIncomingShare(file);
    }, onError: (_) {});

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final file = await ExternalShareService.instance.getInitialSharedFile();
      await ExternalShareService.instance.reset();
      if (mounted && file != null) {
        await _handleIncomingShare(file);
      }
      await _consumePendingShareIfNeeded();
    });
  }

  Future<void> _handleIncomingShare(SharedIncomingFile file) async {
    await ExternalShareService.instance.reset();
    if (!mounted) return;

    final restored = ref.read(restoreSessionProvider).valueOrNull ?? false;
    if (!restored) {
      await _pendingStore.save(file);
      return;
    }

    appRouter.push('/external-upload', extra: file);
  }

  Future<void> _consumePendingShareIfNeeded() async {
    final restored = ref.read(restoreSessionProvider).valueOrNull ?? false;
    if (!restored) return;

    final pending = await _pendingStore.load();
    if (!mounted || pending == null) return;

    await _pendingStore.clear();
    appRouter.push('/external-upload', extra: pending);
  }

  @override
  void dispose() {
    _externalShareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(restorePreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final localeOption = ref.watch(localeProvider);
    final _ = ref.watch(recoverSessionProvider);
    final seedColor = seedColorFor(themeColor);

    return MaterialApp.router(
      title: '群晖管家',
      theme: AppTheme.light(seedColor),
      darkTheme: AppTheme.dark(seedColor),
      themeMode: themeModeFor(themeMode),
      locale: localeFor(localeOption),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
