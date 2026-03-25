import 'package:flutter/material.dart';

import '../../../../domain/entities/information_center.dart';
import 'information_center_shared.dart';

class NetworkTab extends StatelessWidget {
  final InformationCenterData info;

  const NetworkTab({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          icon: Icons.public_outlined,
          title: '网络 · 基本信息',
          children: [
            InfoRow(label: 'DNS', value: info.dnsServer),
            InfoRow(label: '网关', value: info.gateway),
            InfoRow(label: '工作群组', value: info.workgroup),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.lan_outlined,
          title: '网络 · 局域网',
          children: info.lanNetworks.isEmpty
              ? const [EmptyHint(text: '暂未获取到局域网信息')]
              : info.lanNetworks.map((item) => NetworkTile(network: item)).toList(),
        ),
      ],
    );
  }
}
