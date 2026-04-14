import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../../../preferences/providers/preferences_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String _themeModeLabel(AppThemeModeOption option) {
    switch (option) {
      case AppThemeModeOption.light:
        return l10n.lightMode;
      case AppThemeModeOption.dark:
        return l10n.darkMode;
      case AppThemeModeOption.system:
        return l10n.followSystem;
    }
  }

  String _themeColorLabel(AppThemeColorOption option) {
    switch (option) {
      case AppThemeColorOption.green:
        return l10n.themeColorGreen;
      case AppThemeColorOption.orange:
        return l10n.themeColorOrange;
      case AppThemeColorOption.purple:
        return l10n.themeColorPurple;
      case AppThemeColorOption.blue:
        return l10n.themeColorBlue;
    }
  }

  String _localeLabel(AppLocaleOption option) {
    switch (option) {
      case AppLocaleOption.zh:
        return l10n.simplifiedChinese;
      case AppLocaleOption.en:
        return l10n.english;
      case AppLocaleOption.system:
        return l10n.followSystem;
    }
  }

  Future<void> _showThemeModeSheet(BuildContext context, WidgetRef ref, AppThemeModeOption current) async {
    final result = await showModalBottomSheet<AppThemeModeOption>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.themeMode, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _BottomSheetOption<AppThemeModeOption>(
              value: AppThemeModeOption.system,
              groupValue: current,
              label: l10n.followSystem,
              icon: Icons.brightness_auto,
              onTap: () => Navigator.pop(context, AppThemeModeOption.system),
            ),
            _BottomSheetOption<AppThemeModeOption>(
              value: AppThemeModeOption.light,
              groupValue: current,
              label: l10n.lightMode,
              icon: Icons.light_mode,
              onTap: () => Navigator.pop(context, AppThemeModeOption.light),
            ),
            _BottomSheetOption<AppThemeModeOption>(
              value: AppThemeModeOption.dark,
              groupValue: current,
              label: l10n.darkMode,
              icon: Icons.dark_mode,
              onTap: () => Navigator.pop(context, AppThemeModeOption.dark),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    if (result != null) {
      ref.read(saveThemeModeProvider)(result);
    }
  }

  Future<void> _showThemeColorSheet(BuildContext context, WidgetRef ref, AppThemeColorOption current) async {
    final result = await showModalBottomSheet<AppThemeColorOption>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.themeColor, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _BottomSheetOption<AppThemeColorOption>(
              value: AppThemeColorOption.blue,
              groupValue: current,
              label: l10n.themeColorBlue,
              icon: Icons.circle,
              iconColor: Colors.blue,
              onTap: () => Navigator.pop(context, AppThemeColorOption.blue),
            ),
            _BottomSheetOption<AppThemeColorOption>(
              value: AppThemeColorOption.green,
              groupValue: current,
              label: l10n.themeColorGreen,
              icon: Icons.circle,
              iconColor: Colors.green,
              onTap: () => Navigator.pop(context, AppThemeColorOption.green),
            ),
            _BottomSheetOption<AppThemeColorOption>(
              value: AppThemeColorOption.orange,
              groupValue: current,
              label: l10n.themeColorOrange,
              icon: Icons.circle,
              iconColor: Colors.orange,
              onTap: () => Navigator.pop(context, AppThemeColorOption.orange),
            ),
            _BottomSheetOption<AppThemeColorOption>(
              value: AppThemeColorOption.purple,
              groupValue: current,
              label: l10n.themeColorPurple,
              icon: Icons.circle,
              iconColor: Colors.purple,
              onTap: () => Navigator.pop(context, AppThemeColorOption.purple),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    if (result != null) {
      ref.read(saveThemeColorProvider)(result);
    }
  }

  Future<void> _showLocaleSheet(BuildContext context, WidgetRef ref, AppLocaleOption current) async {
    final result = await showModalBottomSheet<AppLocaleOption>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l10n.language, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            _BottomSheetOption<AppLocaleOption>(
              value: AppLocaleOption.system,
              groupValue: current,
              label: l10n.followSystem,
              icon: Icons.settings_suggest,
              onTap: () => Navigator.pop(context, AppLocaleOption.system),
            ),
            _BottomSheetOption<AppLocaleOption>(
              value: AppLocaleOption.zh,
              groupValue: current,
              label: l10n.simplifiedChinese,
              icon: Icons.language,
              onTap: () => Navigator.pop(context, AppLocaleOption.zh),
            ),
            _BottomSheetOption<AppLocaleOption>(
              value: AppLocaleOption.en,
              groupValue: current,
              label: l10n.english,
              icon: Icons.language,
              onTap: () => Navigator.pop(context, AppLocaleOption.en),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    if (result != null) {
      ref.read(saveLocaleProvider)(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final server = ref.watch(currentConnectionProvider).server;
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final locale = ref.watch(localeProvider);
    final downloadDirectory = ref.watch(downloadDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionCard(
            title: l10n.settingsConnectionStorage,
            subtitle: server == null ? l10n.noSessionPleaseLogin : l10n.settingsConnectionStorageSubtitle,
            children: [
              _SettingsActionTile(
                icon: Icons.folder_open_rounded,
                title: l10n.settingsDownloadDirectory,
                subtitle: downloadDirectory ?? l10n.downloadDirectoryHint,
                onTap: () async {
                  final selected = await FilePicker.platform.getDirectoryPath();
                  if (selected == null || selected.isEmpty) return;
                  await ref.read(saveDownloadDirectoryProvider)(selected);
                  if (context.mounted) {
                    Toast.success(l10n.settingsDownloadDirUpdated);
                  }
                },
              ),
              _SettingsActionTile(
                icon: Icons.link_rounded,
                title: l10n.sharingLinksTitle,
                subtitle: l10n.sharingLinksHint,
                onTap: () => context.push('/sharing-links'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsAppearanceLanguage,
            subtitle: l10n.settingsAppearanceSubtitle,
            children: [
              _SettingsActionTile(
                icon: Icons.brightness_6_rounded,
                title: l10n.themeMode,
                subtitle: _themeModeLabel(themeMode),
                onTap: () => _showThemeModeSheet(context, ref, themeMode),
              ),
              _SettingsActionTile(
                icon: Icons.palette_rounded,
                title: l10n.themeColor,
                subtitle: _themeColorLabel(themeColor),
                onTap: () => _showThemeColorSheet(context, ref, themeColor),
              ),
              _SettingsActionTile(
                icon: Icons.language_rounded,
                title: l10n.language,
                subtitle: _localeLabel(locale),
                onTap: () => _showLocaleSheet(context, ref, locale),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsAppSupport,
            subtitle: l10n.settingsAppSupportSubtitle,
            children: [
              _SettingsActionTile(
                icon: Icons.receipt_long_rounded,
                title: l10n.appLogsTitle,
                subtitle: l10n.appLogsSubtitle,
                onTap: () => context.push('/app-logs'),
              ),
              _SettingsActionTile(
                icon: Icons.logout_rounded,
                title: l10n.settingsLogout,
                subtitle: l10n.settingsLogoutSubtitle,
                iconColor: theme.colorScheme.error,
                textColor: theme.colorScheme.error,
                onTap: () async {
                  await ref.read(logoutProvider)();
                  if (context.mounted) context.go('/login');
                },
              ),
              _SettingsActionTile(
                icon: Icons.info_outline_rounded,
                title: l10n.settingsAbout,
                subtitle: l10n.settingsAboutSubtitle,
                onTap: () => context.push('/about'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? theme.colorScheme.primary;
    final resolvedTextColor = textColor ?? theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: resolvedIconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: resolvedIconColor),
        ),
        title: Text(title, style: TextStyle(color: resolvedTextColor, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _BottomSheetOption<T> extends StatelessWidget {
  const _BottomSheetOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final T value;
  final T groupValue;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
