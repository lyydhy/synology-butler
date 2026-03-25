import 'package:flutter/material.dart';

import '../../../../domain/entities/information_center.dart';
import '../../../../domain/entities/system_status.dart';

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const SectionCard({
    super.key,
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
        border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.14)),
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
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

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? color;

  const InfoRow(
      {super.key, required this.label, required this.value, this.color});

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
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const InfoTile({
    super.key,
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

class EmptyHint extends StatelessWidget {
  final String text;

  const EmptyHint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class InfoBadge extends StatelessWidget {
  final String text;
  final IconData icon;

  const InfoBadge({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}

class NetworkTile extends StatelessWidget {
  final InformationCenterLanNetwork network;

  const NetworkTile({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.lan_outlined),
      ),
      title: Text(network.name),
      subtitle: Text(
        [network.ipAddress, network.subnetMask, network.macAddress]
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .join(' · '),
      ),
    );
  }
}

class DiskTile extends StatelessWidget {
  final InformationCenterDisk disk;

  const DiskTile({super.key, required this.disk});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.album_outlined),
      ),
      title: Text(disk.name),
      subtitle: Text(
        [disk.serialNumber, disk.temperatureText]
            .whereType<String>()
            .where((e) => e.trim().isNotEmpty)
            .join(' · '),
      ),
      trailing: Text(_formatBytes(disk.capacityBytes)),
    );
  }
}

class VolumeUsageTile extends StatelessWidget {
  final StorageVolumeStatus volume;
  final int index;

  const VolumeUsageTile({super.key, required this.volume, required this.index});

  @override
  Widget build(BuildContext context) {
    final usage = volume.usage.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(volume.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${usage.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: usage / 100, minHeight: 10),
        ),
        const SizedBox(height: 8),
        Text(
            '${_formatBytes(volume.usedBytes)} / ${_formatBytes(volume.totalBytes)}'),
      ],
    );
  }
}

String formatBytes(double? value) => _formatBytes(value);

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
