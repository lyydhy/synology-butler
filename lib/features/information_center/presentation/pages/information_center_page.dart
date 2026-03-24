import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/information_center.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/information_center_providers.dart';

class InformationCenterPage extends ConsumerWidget {
  const InformationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(informationCenterProvider);
    final overviewAsync = ref.watch(dashboardOverviewSafeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('信息中心'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              ref.invalidate(informationCenterProvider);
              ref.invalidate(dashboardBaseOverviewProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: infoAsync.when(
        data: (info) {
          final overview = overviewAsync.valueOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.serverName,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(info.dsmVersion?.trim().isNotEmpty == true ? info.dsmVersion! : 'DSM 版本未知'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Badge(text: info.modelName ?? '型号未知', icon: Icons.memory_outlined),
                        _Badge(text: info.serialNumber ?? '序列号未知', icon: Icons.qr_code_2_outlined),
                        _Badge(text: info.timezone ?? '时区未知', icon: Icons.schedule_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.info_outline,
                title: '基本信息',
                children: [
                  _InfoRow(label: '产品序列号', value: info.serialNumber),
                  _InfoRow(label: '产品型号', value: info.modelName),
                  _InfoRow(label: 'CPU', value: info.cpuName),
                  _InfoRow(label: 'CPU 核心', value: info.cpuCores?.toString()),
                  _InfoRow(label: '物理内存', value: _formatBytes(info.memoryBytes)),
                  _InfoRow(label: 'DSM 版本', value: info.dsmVersion),
                  _InfoRow(label: '系统时间', value: info.systemTime),
                  _InfoRow(label: '运行时间', value: info.uptimeText),
                  _InfoRow(label: '散热状态', value: info.thermalStatus),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.access_time_outlined,
                title: '时间信息',
                children: [
                  _InfoRow(label: '服务器地址', value: info.serverName),
                  _InfoRow(label: '时区', value: info.timezone),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.usb_outlined,
                title: '外接设备',
                children: info.externalDevices.isEmpty
                    ? const [_EmptyHint(text: '暂未获取到外接设备信息')]
                    : info.externalDevices
                        .map((item) => _InfoTile(
                              title: item.name,
                              subtitle: [item.type, item.status].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · '),
                              icon: Icons.usb_rounded,
                            ))
                        .toList(),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.public_outlined,
                title: '网络 · 基本信息',
                children: [
                  _InfoRow(label: 'DNS', value: info.dnsServer),
                  _InfoRow(label: '网关', value: info.gateway),
                  _InfoRow(label: '工作群组', value: info.workgroup),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.lan_outlined,
                title: '网络 · 局域网',
                children: info.lanNetworks.isEmpty
                    ? const [_EmptyHint(text: '暂未获取到局域网信息')]
                    : info.lanNetworks
                        .map((item) => _NetworkTile(network: item))
                        .toList(),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.storage_rounded,
                title: '存储 · 存储空间',
                children: [
                  if ((overview?.volumes ?? const []).isEmpty)
                    const _EmptyHint(text: '暂未获取到存储空间信息')
                  else
                    ...(overview!.volumes.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: entry.key == overview.volumes.length - 1 ? 0 : 14),
                        child: _VolumeUsageTile(volume: entry.value, index: entry.key),
                      ),
                    )),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                icon: Icons.album_outlined,
                title: '存储 · 硬盘',
                children: info.disks.isEmpty
                    ? const [_EmptyHint(text: '暂未获取到硬盘信息')]
                    : info.disks
                        .map((item) => _DiskTile(disk: item))
                        .toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('信息中心加载失败\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  String _formatBytes(double? value) {
    if (value == null || value <= 0) return '--';
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value == null || value!.trim().isEmpty ? '--' : value!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle.isEmpty ? '--' : subtitle),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  final InformationCenterLanNetwork network;

  const _NetworkTile({required this.network});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(network.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _InfoRow(label: 'MAC 地址', value: network.macAddress),
          _InfoRow(label: '局域网 IP', value: network.ipAddress),
          _InfoRow(label: '子网掩码', value: network.subnetMask),
        ],
      ),
    );
  }
}

class _DiskTile extends StatelessWidget {
  final InformationCenterDisk disk;

  const _DiskTile({required this.disk});

  String _formatBytes(double? value) {
    if (value == null || value <= 0) return '--';
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(disk.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _InfoRow(label: '序列号', value: disk.serialNumber),
          _InfoRow(label: '容量', value: _formatBytes(disk.capacityBytes)),
          _InfoRow(label: '温度', value: disk.temperatureText),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: Colors.grey.shade700));
  }
}

class _VolumeUsageTile extends StatelessWidget {
  final dynamic volume;
  final int index;

  const _VolumeUsageTile({
    required this.volume,
    required this.index,
  });

  String _formatBytes(double? value) {
    if (value == null || value <= 0) return '--';

    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value;
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final digits = size >= 100 ? 0 : (size >= 10 ? 1 : 2);
    return '${size.toStringAsFixed(digits)} ${units[unitIndex]}';
  }

  String _buildDisplayName() {
    final raw = volume.name.trim();
    if (raw.isEmpty) return '存储空间${index + 1}';

    final match = RegExp(r'^volume\s*(\d+)$', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      return '存储空间${match.group(1)}';
    }

    if (raw.toLowerCase().startsWith('volume')) {
      return '存储空间${index + 1}';
    }

    return raw;
  }

  String _buildUsageDetail() {
    final used = volume.usedBytes as double?;
    final total = volume.totalBytes as double?;

    if (used != null && used > 0 && total != null && total > 0) {
      return '已用 ${_formatBytes(used)} / 总计 ${_formatBytes(total)}';
    }

    if (used != null && used > 0) {
      return '已用 ${_formatBytes(used)} / 总计 --';
    }

    if (total != null && total > 0) {
      return '已用 -- / 总计 ${_formatBytes(total)}';
    }

    return '已用 -- / 总计 --';
  }

  @override
  Widget build(BuildContext context) {
    final usage = (volume.usage as double).isNaN ? 0.0 : volume.usage as double;
    final ratio = (usage / 100).clamp(0.0, 1.0);
    final displayName = _buildDisplayName();
    final usageDetail = _buildUsageDetail();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${usage.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          usageDetail,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ],
    );
  }
}
