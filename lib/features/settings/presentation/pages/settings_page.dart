import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/server_url_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../preferences/providers/preferences_providers.dart';
import '../widgets/server_list_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  String themeModeLabel(AppLocalizations l10n, AppThemeModeOption option) {
    switch (option) {
      case AppThemeModeOption.light:
        return l10n.lightMode;
      case AppThemeModeOption.dark:
        return l10n.darkMode;
      case AppThemeModeOption.system:
        return l10n.followSystem;
    }
  }

  String themeColorLabel(AppThemeColorOption option) {
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

  String localeLabel(AppLocalizations l10n, AppLocaleOption option) {
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
    final l10n = AppLocalizations.of(context);
    final server = ref.watch(currentServerProvider);
    final session = ref.watch(currentSessionProvider);
    final savedServers = ref.watch(savedServersProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final locale = ref.watch(localeProvider);
    final downloadDirectory = ref.watch(downloadDirectoryProvider);

    final serverLabel = server == null
        ? l10n.notAvailableYet
        : '${server.name} · ${ServerUrlHelper.buildBaseUrl(server)}';

    final sidLabel = session == null ? l10n.notLoggedIn : l10n.loggedInSidEstablished;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(title: Text(l10n.currentDevice), subtitle: Text(serverLabel)),
          ListTile(title: Text(l10n.loginStatus), subtitle: Text(sidLabel)),
          ListTile(
            title: Text(l10n.themeMode),
            subtitle: Text(themeModeLabel(l10n, themeMode)),
            trailing: DropdownButton<AppThemeModeOption>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) ref.read(saveThemeModeProvider)(value);
              },
              items: [
                DropdownMenuItem(value: AppThemeModeOption.system, child: Text(l10n.followSystem)),
                DropdownMenuItem(value: AppThemeModeOption.light, child: Text(l10n.lightMode)),
                DropdownMenuItem(value: AppThemeModeOption.dark, child: Text(l10n.darkMode)),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.themeColor),
            subtitle: Text(themeColorLabel(themeColor)),
            trailing: DropdownButton<AppThemeColorOption>(
              value: themeColor,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) ref.read(saveThemeColorProvider)(value);
              },
              items: const [
                DropdownMenuItem(value: AppThemeColorOption.blue, child: Text('Blue')),
                DropdownMenuItem(value: AppThemeColorOption.green, child: Text('Green')),
                DropdownMenuItem(value: AppThemeColorOption.orange, child: Text('Orange')),
                DropdownMenuItem(value: AppThemeColorOption.purple, child: Text('Purple')),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(localeLabel(l10n, locale)),
            trailing: DropdownButton<AppLocaleOption>(
              value: locale,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) ref.read(saveLocaleProvider)(value);
              },
              items: [
                DropdownMenuItem(value: AppLocaleOption.system, child: Text(l10n.followSystem)),
                DropdownMenuItem(value: AppLocaleOption.zh, child: Text(l10n.simplifiedChinese)),
                DropdownMenuItem(value: AppLocaleOption.en, child: Text(l10n.english)),
              ],
            ),
          ),
          ListTile(
            title: const Text('下载目录'),
            subtitle: Text(downloadDirectory ?? '首次下载时选择，之后可在这里修改'),
            trailing: const Icon(Icons.folder_open_outlined),
            onTap: () async {
              final selected = await FilePicker.platform.getDirectoryPath();
              if (selected != null && selected.isNotEmpty) {
                await ref.read(saveDownloadDirectoryProvider)(selected);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('下载目录已更新')),
                  );
                }
              }
            },
          ),
          const ListTile(title: Text('证书策略'), subtitle: Text('默认严格校验')),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('已保存设备', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ServerListCard(
            servers: savedServers,
            currentServerId: server?.id,
            onSelect: (selected) async {
              await ref.read(switchCurrentServerProvider)(selected);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.switchDeviceRelogin)),
                );
                context.go('/login');
              }
            },
          ),
          ListTile(
            title: const Text('信息中心'),
            subtitle: const Text('查看系统、网络、存储和硬盘信息'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/information-center'),
          ),
          ListTile(
            title: const Text('套件中心'),
            subtitle: const Text('查看 DSM 套件商店、已安装应用和可更新项目'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/packages'),
          ),
          ListTile(
            title: Text(l10n.serverManagement),
            subtitle: const Text('查看、切换、编辑和删除已保存设备'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/servers'),
          ),
          ListTile(
            title: Text(l10n.debugInfo),
            subtitle: const Text('查看当前连接、本地保存状态和联调提示'),
            trailing: const Icon(Icons.bug_report_outlined),
            onTap: () => context.go('/debug'),
          ),
          ListTile(
            title: Text(l10n.appLogsTitle),
            subtitle: Text(l10n.appLogsSubtitle),
            trailing: const Icon(Icons.receipt_long_outlined),
            onTap: () => context.push('/app-logs'),
          ),
          const ListTile(
            title: Text('模块诊断'),
            subtitle: Text('快速测试认证、文件和下载模块的联通情况'),
            trailing: Icon(Icons.medical_information_outlined),
          ),
          ListTile(
            title: const Text('打开模块诊断'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/diagnostics'),
          ),
          ListTile(
            title: Text(l10n.addNewDevice),
            subtitle: const Text('跳转到登录页配置新的 NAS 连接'),
            trailing: const Icon(Icons.add),
            onTap: () => context.go('/login'),
          ),
          ListTile(
            title: const Text('退出登录'),
            subtitle: const Text('清除当前会话和本地保存的登录态'),
            trailing: const Icon(Icons.logout),
            onTap: () async {
              await ref.read(logoutProvider)();
              if (context.mounted) context.go('/login');
            },
          ),
          const ListTile(title: Text('关于'), subtitle: Text('群晖管家 v0.1')),
        ],
      ),
    );
  }
}
