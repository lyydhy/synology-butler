import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
import '../../../upgrade/presentation/providers/upgrade_providers.dart';

class ControlPanelPage extends ConsumerWidget {
  const ControlPanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUpdate = ref.watch(hasUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.controlPanelTitle),
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (hasUpdate)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => context.push('/upgrade'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '有更新',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 核心功能
          _SectionCard(
            title: l10n.coreFeatures,
            items: [
              _PanelItem(
                icon: Icons.info_outline_rounded,
                title: l10n.informationCenterTitle,
                subtitle: l10n.infoCenterSubtitle,
                onTap: () => context.push('/information-center'),
              ),
              _PanelItem(
                icon: Icons.system_update_alt_rounded,
                title: l10n.updateStatus,
                subtitle: l10n.updateStatusSubtitle,
                badge: hasUpdate ? '更新' : null,
                onTap: () => context.push('/upgrade'),
              ),
              _PanelItem(
                icon: Icons.public_rounded,
                title: l10n.externalAccessTitle,
                subtitle: l10n.externalAccessSubtitle,
                onTap: () => context.push('/external-access'),
              ),
              _PanelItem(
                icon: Icons.perm_media_outlined,
                title: l10n.indexServiceTitle,
                subtitle: l10n.indexServiceSubtitle,
                onTap: () => context.push('/index-service'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 系统管理
          _SectionCard(
            title: l10n.systemManagement,
            items: [
              _PanelItem(
                icon: Icons.schedule_rounded,
                title: l10n.taskSchedulerTitle,
                subtitle: l10n.taskSchedulerSubtitle,
                onTap: () => context.push('/task-scheduler'),
              ),
              _PanelItem(
                icon: Icons.usb_rounded,
                title: l10n.externalDevicesTitle,
                subtitle: l10n.externalDevicesSubtitle,
                onTap: () => context.push('/external-devices'),
              ),
              _PanelItem(
                icon: Icons.folder_shared_outlined,
                title: l10n.sharedFoldersTitle,
                subtitle: l10n.sharedFoldersSubtitle,
                onTap: () => context.push('/shared-folders'),
              ),
              _PanelItem(
                icon: Icons.group_outlined,
                title: l10n.userGroupsTitle,
                subtitle: l10n.userGroupsSubtitle,
                onTap: () => context.push('/user-groups'),
              ),
              _PanelItem(
                icon: Icons.dns_outlined,
                title: l10n.fileServicesTitle,
                subtitle: l10n.fileServicesSubtitle,
                onTap: () => context.push('/file-services'),
              ),
              _PanelItem(
                icon: Icons.lan_outlined,
                title: l10n.networkTitle,
                subtitle: l10n.networkSubtitle,
                onTap: () => context.push('/network'),
              ),
              _PanelItem(
                icon: Icons.terminal_rounded,
                title: '终端设置',
                subtitle: 'SSH 与 Telnet 服务',
                onTap: () => context.push('/terminal'),
              ),
              _PanelItem(
                icon: Icons.power_settings_new_rounded,
                title: '电源管理',
                subtitle: '关机与重启',
                onTap: () => context.push('/power'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 分组卡片组件
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SectionCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }
}

/// 面板列表项组件
class _PanelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;

  const _PanelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInteractive = onTap != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(
                    alpha: isInteractive ? 1.0 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: colorScheme.onPrimaryContainer.withValues(
                    alpha: isInteractive ? 1.0 : 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isInteractive
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: isInteractive ? 1.0 : 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (isInteractive) ...[
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
