import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/preferences/providers/preferences_providers.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class QunhuiManagerApp extends ConsumerWidget {
  const QunhuiManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
