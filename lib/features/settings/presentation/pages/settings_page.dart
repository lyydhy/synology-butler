import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
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
        return 'Green';
      case AppThemeColorOption.orange:
        return 'Orange';
      case AppThemeColorOption.purple:
        return 'Purple';
      case AppThemeColorOption.blue:
        return 'Blue';
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
            subtitle: server == null ? l10n.noSessionPleaseLogin : '管理 NAS 连接和本地下载目录',
            children: [
              _SettingsActionTile(
                icon: Icons.dns_rounded,
                title: l10n.settingsConnectionManagement,
                subtitle: server == null ? '查看、切换、编辑和删除已保存设备' : '当前设备：${server.name}',
                onTap: () => context.push('/servers'),
              ),
              _SettingsActionTile(
                icon: Icons.folder_open_rounded,
                title: l10n.settingsDownloadDirectory,
                subtitle: downloadDirectory ?? '首次下载时选择，之后可在这里修改',
                onTap: () async {
                  final selected = await FilePicker.platform.getDirectoryPath();
                  if (selected == null || selected.isEmpty) return;
                  await ref.read(saveDownloadDirectoryProvider)(selected);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsDownloadDirUpdated)),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: l10n.settingsAppearanceLanguage,
            subtitle: l10n.settingsAppearanceSubtitle,
            children: [
              _SettingsDropdownTile<AppThemeModeOption>(
                icon: Icons.brightness_6_rounded,
                title: l10n.themeMode,
                subtitle: _themeModeLabel(themeMode),
                value: themeMode,
                items: [
                  DropdownMenuItem(value: AppThemeModeOption.system, child: Text(l10n.followSystem)),
                  DropdownMenuItem(value: AppThemeModeOption.light, child: Text(l10n.lightMode)),
                  DropdownMenuItem(value: AppThemeModeOption.dark, child: Text(l10n.darkMode)),
                ],
                onChanged: (value) {
                  if (value != null) ref.read(saveThemeModeProvider)(value);
                },
              ),
              _SettingsDropdownTile<AppThemeColorOption>(
                icon: Icons.palette_rounded,
                title: l10n.themeColor,
                subtitle: _themeColorLabel(themeColor),
                value: themeColor,
                items: const [
                  DropdownMenuItem(value: AppThemeColorOption.blue, child: Text('Blue')),
                  DropdownMenuItem(value: AppThemeColorOption.green, child: Text('Green')),
                  DropdownMenuItem(value: AppThemeColorOption.orange, child: Text('Orange')),
                  DropdownMenuItem(value: AppThemeColorOption.purple, child: Text('Purple')),
                ],
                onChanged: (value) {
                  if (value != null) ref.read(saveThemeColorProvider)(value);
                },
              ),
              _SettingsDropdownTile<AppLocaleOption>(
                icon: Icons.language_rounded,
                title: l10n.language,
                subtitle: _localeLabel(locale),
                value: locale,
                items: [
                  DropdownMenuItem(value: AppLocaleOption.system, child: Text(l10n.followSystem)),
                  DropdownMenuItem(value: AppLocaleOption.zh, child: Text(l10n.simplifiedChinese)),
                  DropdownMenuItem(value: AppLocaleOption.en, child: Text(l10n.english)),
                ],
                onChanged: (value) {
                  if (value != null) ref.read(saveLocaleProvider)(value);
                },
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
              const _SettingsStaticTile(
                icon: Icons.info_outline_rounded,
                title: '关于',
                subtitle: '群晖管家 v0.1',
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

    return ListTile(
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
    );
  }
}

class _SettingsStaticTile extends StatelessWidget {
  const _SettingsStaticTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _SettingsDropdownTile<T> extends StatelessWidget {
  const _SettingsDropdownTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        onChanged: onChanged,
        items: items,
      ),
    );
  }
}
