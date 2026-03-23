import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/server_url_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class DebugInfoPage extends ConsumerWidget {
  const DebugInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentServer = ref.watch(currentServerProvider);
    final currentSession = ref.watch(currentSessionProvider);
    final savedServers = ref.watch(savedServersProvider);
    final savedUsername = ref.watch(savedUsernameProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.debugInfo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.debugCurrentConnection, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.currentDevice),
            subtitle: Text(currentServer == null ? l10n.notAvailableYet : currentServer.name),
          ),
          ListTile(
            title: const Text('Base URL'),
            subtitle: Text(currentServer == null ? l10n.notAvailableYet : ServerUrlHelper.buildBaseUrl(currentServer)),
          ),
          ListTile(
            title: Text(l10n.sessionStatus),
            subtitle: Text(currentSession == null ? l10n.notAvailableYet : 'SID established (serverId=${currentSession.serverId})'),
          ),
          ListTile(
            title: const Text('SynoToken'),
            subtitle: Text(currentSession == null
                ? l10n.notAvailableYet
                : (currentSession.synoToken == null || currentSession.synoToken!.isEmpty ? 'missing' : 'present')),
          ),
          ListTile(
            title: const Text('Cookie Header'),
            subtitle: Text(currentSession == null
                ? l10n.notAvailableYet
                : (currentSession.cookieHeader == null || currentSession.cookieHeader!.isEmpty ? 'missing' : 'present')),
          ),
          const SizedBox(height: 16),
          Text(l10n.debugLocalStorage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.savedUsername),
            subtitle: Text(savedUsername ?? l10n.notAvailableYet),
          ),
          ListTile(
            title: Text(l10n.savedDeviceCount),
            subtitle: Text('${savedServers.length}'),
          ),
          ...savedServers.map(
            (server) => ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(server.name),
              subtitle: Text(ServerUrlHelper.buildBaseUrl(server)),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.debugTips, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            title: Text('1. 先测连接再登录'),
            subtitle: Text('优先确认 query.cgi / auth.cgi 可访问，再排查账号问题'),
          ),
          const ListTile(
            title: Text('2. 证书错误优先检查 HTTPS'),
            subtitle: Text('自签名证书或反向代理配置常导致调试失败'),
          ),
          const ListTile(
            title: Text('3. 文件/下载接口要看账号权限'),
            subtitle: Text('即使登录成功，功能接口仍可能因权限不足失败'),
          ),
        ],
      ),
    );
  }
}
