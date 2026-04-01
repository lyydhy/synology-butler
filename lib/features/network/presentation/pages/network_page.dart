import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/network.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

/// 网络状态 Provider
final networkProvider = FutureProvider<NetworkModel>((ref) async {
  return ref.read(systemRepositoryProvider).fetchNetwork();
});

class NetworkPage extends ConsumerWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkAsync = ref.watch(networkProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.networkTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(networkProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: networkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(networkProvider),
          actionLabel: '重新加载',
        ),
        data: (network) {
          final allInterfaces = [...network.ethernets, ...network.pppoes];
          if (network.general == null && allInterfaces.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lan_outlined, size: 52),
                    const SizedBox(height: 12),
                    Text(l10n.noNetworkInfo),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 常规信息卡片
              if (network.general != null) _GeneralCard(general: network.general!),

              // 网络接口
              if (allInterfaces.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(title: l10n.networkInterfaces),
                ...allInterfaces.map((iface) => _InterfaceCard(iface: iface)),
              ],

              // 代理设置
              if (network.proxy != null && network.proxy!.enable) ...[
                const SizedBox(height: 8),
                _SectionHeader(title: l10n.proxySettings),
                _ProxyCard(proxy: network.proxy!),
              ],

              // 网关信息
              if (network.gateway != null && network.gateway!.routes.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(title: l10n.gatewayInfo),
                ...network.gateway!.routes.map((route) => _GatewayCard(route: route)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GeneralCard extends StatelessWidget {
  final NetworkGeneral general;

  const _GeneralCard({required this.general});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.dns_rounded, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.networkGeneral,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      general.serverName,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetaRow(label: l10n.hostname, value: general.serverName),
          if (general.gateway != null && general.gateway!.isNotEmpty)
            _MetaRow(label: l10n.defaultGateway, value: general.gateway!),
          if (general.v6gateway != null && general.v6gateway!.isNotEmpty)
            _MetaRow(label: l10n.ipv6Gateway, value: general.v6gateway!),
          if (general.dnsPrimary != null && general.dnsPrimary!.isNotEmpty)
            _MetaRow(
              label: l10n.dnsPrimary,
              value: general.dnsPrimary!,
              extra: general.dnsManual ? ' (${l10n.manual})' : null,
            ),
          if (general.dnsSecondary != null && general.dnsSecondary!.isNotEmpty)
            _MetaRow(label: l10n.dnsSecondary, value: general.dnsSecondary!),
          if (general.workgroup != null && general.workgroup!.isNotEmpty)
            _MetaRow(label: l10n.workgroup, value: general.workgroup!),
        ],
      ),
    );
  }
}

class _InterfaceCard extends StatelessWidget {
  final NetworkInterface iface;

  const _InterfaceCard({required this.iface});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iface.isConnected ? Colors.green : Colors.grey;

    IconData icon;
    if (iface.id.contains('pppoe') || iface.id.contains('ppp')) {
      icon = Icons.wifi_rounded;
    } else {
      icon = Icons.lan_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iface.displayName.isNotEmpty ? iface.displayName : iface.id,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      iface.isConnected ? l10n.connected : l10n.disconnected,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  iface.isConnected ? 'ON' : 'OFF',
                  style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (iface.isConnected) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (iface.ip != null && iface.ip!.isNotEmpty)
                  _MetaItem(label: l10n.ipAddress, value: iface.ip!),
                if (iface.mask != null && iface.mask!.isNotEmpty)
                  _MetaItem(label: l10n.subnetMask, value: iface.mask!),
                _MetaItem(label: l10n.dhcp, value: iface.useDhcp ? l10n.enabled : l10n.disabled),
              ],
            ),
            if (iface.maxSupportedSpeed != null) ...[
              const SizedBox(height: 8),
              Text(
                '${iface.speedDisplay}, ${iface.duplexDisplay}, MTU ${iface.mtu ?? 1500}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (iface.ipv6.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.ipv6Address}:',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              ...iface.ipv6.map((ip) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  ip,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProxyCard extends StatelessWidget {
  final ProxySettings proxy;

  const _ProxyCard({required this.proxy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.withValues(alpha: 0.12),
                child: const Icon(Icons.vpn_lock_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.proxySettings,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.enabled,
                  style: theme.textTheme.labelMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (proxy.httpHost != null && proxy.httpHost!.isNotEmpty)
            _MetaRow(label: 'HTTP ${l10n.address}', value: '${proxy.httpHost}:${proxy.httpPort ?? "80"}'),
          if (proxy.httpsHost != null && proxy.httpsHost!.isNotEmpty)
            _MetaRow(label: 'HTTPS ${l10n.address}', value: '${proxy.httpsHost}:${proxy.httpsPort ?? "443"}'),
          if (proxy.ftpHost != null && proxy.ftpHost!.isNotEmpty)
            _MetaRow(label: 'FTP ${l10n.address}', value: '${proxy.ftpHost}:${proxy.ftpPort ?? "21"}'),
        ],
      ),
    );
  }
}

class _GatewayCard extends StatelessWidget {
  final GatewayRoute route;

  const _GatewayCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.withValues(alpha: 0.12),
            child: const Icon(Icons.router_rounded, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.gateway ?? l10n.unknown,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (route.interfaceName != null)
                  Text(
                    '${l10n.interface}: ${route.interfaceName}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (route.type != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                route.type!.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.blue, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final String? extra;

  const _MetaRow({required this.label, required this.value, this.extra});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label：',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          Expanded(
            child: Text(
              value + (extra ?? ''),
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
