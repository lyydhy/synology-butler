import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ControlPanelPage extends StatelessWidget {
  const ControlPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('控制面板')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionCard(
            title: '第一阶段',
            subtitle: '优先落地低风险、高价值能力',
            items: [
              _PanelItem(
                icon: Icons.info_outline_rounded,
                title: '信息中心',
                subtitle: '已具备基础能力',
                status: '已具备',
                statusColor: Colors.green,
                onTap: () => context.push('/information-center'),
              ),
              const _PanelItem(
                icon: Icons.system_update_alt_rounded,
                title: '更新状态',
                subtitle: '已具备基础能力，后续并入控制面板',
                status: '已具备',
                statusColor: Colors.green,
              ),
              _PanelItem(
                icon: Icons.public_rounded,
                title: '外部访问',
                subtitle: '查看 DDNS 状态并手动刷新',
                status: '进行中',
                statusColor: Colors.orange,
                onTap: () => context.push('/external-access'),
              ),
              _PanelItem(
                icon: Icons.perm_media_outlined,
                title: '索引服务',
                subtitle: '查看状态、调整缩图质量、重建索引',
                status: '已接入',
                statusColor: Colors.green,
                onTap: () => context.push('/index-service'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '后续阶段',
            subtitle: '按风险和依赖递进推进',
            items: [
              _PanelItem(
                icon: Icons.schedule_rounded,
                title: '任务计划',
                subtitle: '列表展示、启停、立即执行',
                status: '已接入',
                statusColor: Colors.green,
                onTap: () => context.push('/task-scheduler'),
              ),
              _PanelItem(
                icon: Icons.usb_rounded,
                title: '外接设备',
                subtitle: '设备列表、基本状态、弹出设备',
                status: '已接入',
                statusColor: Colors.green,
                onTap: () => context.push('/external-devices'),
              ),
              const _StaticPanelItem(icon: Icons.folder_shared_outlined, title: '共享文件夹', subtitle: '第二阶段'),
              const _StaticPanelItem(icon: Icons.group_outlined, title: '用户与群组', subtitle: '第三阶段'),
              const _StaticPanelItem(icon: Icons.dns_outlined, title: '文件服务', subtitle: '第三阶段'),
              const _StaticPanelItem(icon: Icons.lan_outlined, title: '网络', subtitle: '第三阶段'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '当前不纳入范围：终端机和 SNMP。',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> items;

  const _SectionCard({required this.title, required this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;

  const _PanelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Icon(icon, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: theme.textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticPanelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StaticPanelItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _PanelItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      status: '未开始',
      statusColor: Colors.grey,
    );
  }
}
