import 'package:flutter/material.dart';

import '../../../../domain/entities/information_center.dart';
import 'information_center_shared.dart';

class OverviewTab extends StatelessWidget {
  final InformationCenterData info;

  const OverviewTab({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Badge(text: info.modelName ?? '型号未知', icon: Icons.memory_outlined),
                  Badge(text: info.serialNumber ?? '序列号未知', icon: Icons.qr_code_2_outlined),
                  Badge(text: info.timezone ?? '时区未知', icon: Icons.schedule_outlined),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          icon: Icons.info_outline,
          title: '基本信息',
          children: [
            InfoRow(label: '产品序列号', value: info.serialNumber),
            InfoRow(label: '产品型号', value: info.modelName),
            InfoRow(label: 'CPU', value: info.cpuName),
            InfoRow(label: 'CPU 核心', value: info.cpuCores?.toString()),
            InfoRow(label: '物理内存', value: formatBytes(info.memoryBytes)),
            InfoRow(label: 'DSM 版本', value: info.dsmVersion),
            InfoRow(label: '系统时间', value: info.systemTime),
            InfoRow(label: '运行时间', value: info.uptimeText),
            InfoRow(label: '散热状态', value: info.thermalStatus),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.access_time_outlined,
          title: '时间信息',
          children: [
            InfoRow(label: '服务器地址', value: info.serverName),
            InfoRow(label: '时区', value: info.timezone),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.usb_outlined,
          title: '外接设备',
          children: info.externalDevices.isEmpty
              ? const [EmptyHint(text: '暂未获取到外接设备信息')]
              : info.externalDevices
                  .map((item) => InfoTile(
                        title: item.name,
                        subtitle: [item.type, item.status].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · '),
                        icon: Icons.usb_rounded,
                      ))
                  .toList(),
        ),
      ],
    );
  }
}
