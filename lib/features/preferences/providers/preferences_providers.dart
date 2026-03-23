import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/providers/auth_providers.dart';

enum AppThemeModeOption { system, light, dark }

enum AppThemeColorOption { blue, green, orange, purple }

enum AppLocaleOption { system, zh, en }

final themeModeProvider = StateProvider<AppThemeModeOption>((ref) => AppThemeModeOption.system);
final themeColorProvider = StateProvider<AppThemeColorOption>((ref) => AppThemeColorOption.blue);
final localeProvider = StateProvider<AppLocaleOption>((ref) => AppLocaleOption.system);
final downloadDirectoryProvider = StateProvider<String?>((ref) => null);

final restorePreferencesProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(localStorageProvider);

  final themeMode = await storage.readString(AppConstants.themeModeKey);
  final themeColor = await storage.readString(AppConstants.themeColorKey);
  final locale = await storage.readString(AppConstants.localeKey);
  final downloadDirectory = await storage.readString(AppConstants.downloadDirectoryKey);

  ref.read(themeModeProvider.notifier).state = switch (themeMode) {
    'light' => AppThemeModeOption.light,
    'dark' => AppThemeModeOption.dark,
    _ => AppThemeModeOption.system,
  };

  ref.read(themeColorProvider.notifier).state = switch (themeColor) {
    'green' => AppThemeColorOption.green,
    'orange' => AppThemeColorOption.orange,
    'purple' => AppThemeColorOption.purple,
    _ => AppThemeColorOption.blue,
  };

  ref.read(localeProvider.notifier).state = switch (locale) {
    'zh' => AppLocaleOption.zh,
    'en' => AppLocaleOption.en,
    _ => AppLocaleOption.system,
  };

  ref.read(downloadDirectoryProvider.notifier).state = downloadDirectory;
});

final saveThemeModeProvider = Provider<Future<void> Function(AppThemeModeOption)>((ref) {
  return (mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    final storage = ref.read(localStorageProvider);
    await storage.writeString(
      AppConstants.themeModeKey,
      switch (mode) {
        AppThemeModeOption.light => 'light',
        AppThemeModeOption.dark => 'dark',
        AppThemeModeOption.system => 'system',
      },
    );
  };
});

final saveThemeColorProvider = Provider<Future<void> Function(AppThemeColorOption)>((ref) {
  return (color) async {
    ref.read(themeColorProvider.notifier).state = color;
    final storage = ref.read(localStorageProvider);
    await storage.writeString(
      AppConstants.themeColorKey,
      switch (color) {
        AppThemeColorOption.green => 'green',
        AppThemeColorOption.orange => 'orange',
        AppThemeColorOption.purple => 'purple',
        AppThemeColorOption.blue => 'blue',
      },
    );
  };
});

final saveLocaleProvider = Provider<Future<void> Function(AppLocaleOption)>((ref) {
  return (locale) async {
    ref.read(localeProvider.notifier).state = locale;
    final storage = ref.read(localStorageProvider);
    await storage.writeString(
      AppConstants.localeKey,
      switch (locale) {
        AppLocaleOption.zh => 'zh',
        AppLocaleOption.en => 'en',
        AppLocaleOption.system => 'system',
      },
    );
  };
});

final saveDownloadDirectoryProvider = Provider<Future<void> Function(String?)>((ref) {
  return (path) async {
    ref.read(downloadDirectoryProvider.notifier).state = path;
    final storage = ref.read(localStorageProvider);
    if (path == null || path.isEmpty) {
      await storage.remove(AppConstants.downloadDirectoryKey);
    } else {
      await storage.writeString(AppConstants.downloadDirectoryKey, path);
    }
  };
});

Color seedColorFor(AppThemeColorOption option) {
  switch (option) {
    case AppThemeColorOption.green:
      return Colors.green;
    case AppThemeColorOption.orange:
      return Colors.orange;
    case AppThemeColorOption.purple:
      return Colors.purple;
    case AppThemeColorOption.blue:
      return Colors.indigo;
  }
}

ThemeMode themeModeFor(AppThemeModeOption option) {
  switch (option) {
    case AppThemeModeOption.light:
      return ThemeMode.light;
    case AppThemeModeOption.dark:
      return ThemeMode.dark;
    case AppThemeModeOption.system:
      return ThemeMode.system;
  }
}

Locale? localeFor(AppLocaleOption option) {
  switch (option) {
    case AppLocaleOption.zh:
      return const Locale('zh');
    case AppLocaleOption.en:
      return const Locale('en');
    case AppLocaleOption.system:
      return null;
  }
}
