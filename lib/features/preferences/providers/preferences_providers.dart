import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/providers/auth_providers.dart';

enum AppThemeModeOption { system, light, dark }

enum AppThemeColorOption { blue, green, orange, purple }

enum AppLocaleOption { system, zh, en }

enum ContainerDataSourceOption { synology, dpanel }

// ─── Theme Mode ─────────────────────────────────────────────────────────────

class ThemeModeNotifier extends AsyncNotifier<AppThemeModeOption> {
  @override
  Future<AppThemeModeOption> build() async {
    final storage = ref.read(localStorageProvider);
    final value = await storage.readString(AppConstants.themeModeKey);
    return switch (value) {
      'light' => AppThemeModeOption.light,
      'dark' => AppThemeModeOption.dark,
      _ => AppThemeModeOption.system,
    };
  }

  Future<void> save(AppThemeModeOption mode) async {
    state = AsyncData(mode);
    final storage = ref.read(localStorageProvider);
    await storage.writeString(
      AppConstants.themeModeKey,
      switch (mode) {
        AppThemeModeOption.light => 'light',
        AppThemeModeOption.dark => 'dark',
        AppThemeModeOption.system => 'system',
      },
    );
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, AppThemeModeOption>(
  ThemeModeNotifier.new,
);

// ─── Theme Color ─────────────────────────────────────────────────────────────

class ThemeColorNotifier extends AsyncNotifier<AppThemeColorOption> {
  @override
  Future<AppThemeColorOption> build() async {
    final storage = ref.read(localStorageProvider);
    final value = await storage.readString(AppConstants.themeColorKey);
    return switch (value) {
      'green' => AppThemeColorOption.green,
      'orange' => AppThemeColorOption.orange,
      'purple' => AppThemeColorOption.purple,
      _ => AppThemeColorOption.blue,
    };
  }

  Future<void> save(AppThemeColorOption color) async {
    state = AsyncData(color);
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
  }
}

final themeColorProvider = AsyncNotifierProvider<ThemeColorNotifier, AppThemeColorOption>(
  ThemeColorNotifier.new,
);

// ─── Locale ──────────────────────────────────────────────────────────────────

class LocaleNotifier extends AsyncNotifier<AppLocaleOption> {
  @override
  Future<AppLocaleOption> build() async {
    final storage = ref.read(localStorageProvider);
    final value = await storage.readString(AppConstants.localeKey);
    return switch (value) {
      'zh' => AppLocaleOption.zh,
      'en' => AppLocaleOption.en,
      _ => AppLocaleOption.system,
    };
  }

  Future<void> save(AppLocaleOption locale) async {
    state = AsyncData(locale);
    final storage = ref.read(localStorageProvider);
    await storage.writeString(
      AppConstants.localeKey,
      switch (locale) {
        AppLocaleOption.zh => 'zh',
        AppLocaleOption.en => 'en',
        AppLocaleOption.system => 'system',
      },
    );
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, AppLocaleOption>(
  LocaleNotifier.new,
);

// ─── Download Directory ───────────────────────────────────────────────────────

class DownloadDirectoryNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final storage = ref.read(localStorageProvider);
    return storage.readString(AppConstants.downloadDirectoryKey);
  }

  Future<void> save(String? path) async {
    state = AsyncData(path);
    final storage = ref.read(localStorageProvider);
    if (path == null || path.isEmpty) {
      await storage.remove(AppConstants.downloadDirectoryKey);
    } else {
      await storage.writeString(AppConstants.downloadDirectoryKey, path);
    }
  }
}

final downloadDirectoryProvider = AsyncNotifierProvider<DownloadDirectoryNotifier, String?>(
  DownloadDirectoryNotifier.new,
);

// ─── Container Data Source ────────────────────────────────────────────────────

class ContainerDataSourceNotifier extends AsyncNotifier<ContainerDataSourceOption> {
  @override
  Future<ContainerDataSourceOption> build() async {
    final storage = ref.read(localStorageProvider);
    final value = await storage.readString(AppConstants.containerDataSourceKey);
    return switch (value) {
      'dpanel' => ContainerDataSourceOption.dpanel,
      _ => ContainerDataSourceOption.synology,
    };
  }

  Future<void> save(ContainerDataSourceOption source) async {
    state = AsyncData(source);
    final storage = ref.read(localStorageProvider);
    await storage.writeString(
      AppConstants.containerDataSourceKey,
      switch (source) {
        ContainerDataSourceOption.synology => 'synology',
        ContainerDataSourceOption.dpanel => 'dpanel',
      },
    );
  }
}

final containerDataSourceProvider = AsyncNotifierProvider<ContainerDataSourceNotifier, ContainerDataSourceOption>(
  ContainerDataSourceNotifier.new,
);

// ─── Legacy restore provider (kept for compatibility, now a no-op since AsyncNotifier builds on read) ──

final restorePreferencesProvider = FutureProvider<void>((ref) async {
  // Preferences are now restored automatically when each provider is first read.
  // This provider is kept so existing code that watches it still works.
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

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
