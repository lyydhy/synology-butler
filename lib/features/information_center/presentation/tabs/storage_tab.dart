import 'package:flutter/material.dart';

import '../../../../domain/entities/information_center.dart';
import '../../../../domain/entities/system_status.dart';
import 'information_center_shared.dart';

class StorageTab extends StatelessWidget {
  final InformationCenterData info;
  final SystemStatus? overview;

  const StorageTab({super.key, required this.info, required this.overview});

  @override
  Widget build(BuildContext context) {
    final volumes = overview?.volumes ?? const <StorageVolumeStatus>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          icon: Icons.storage_rounded,
          title: '存储 · 存储空间',
          children: [
            if (volumes.isEmpty)
              const EmptyHint(text: '暂未获取到存储空间信息')
            else
              ...(volumes.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: entry.key == volumes.length - 1 ? 0 : 14),
                  child: VolumeUsageTile(volume: entry.value, index: entry.key),
                ),
              )),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.album_outlined,
          title: '存储 · 硬盘',
          children: info.disks.isEmpty
              ? const [EmptyHint(text: '暂未获取到硬盘信息')]
              : info.disks.map((item) => DiskTile(disk: item)).toList(),
        ),
      ],
    );
  }
}
