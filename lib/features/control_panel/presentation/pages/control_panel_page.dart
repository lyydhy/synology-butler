import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';

class ControlPanelPage extends StatelessWidget {
  const ControlPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.controlPanelTitle),
        elevation: 0,
        scrolledUnderElevation: 1,
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
            ],
          ),
        ],
      ),
    );
  }
}

/// 分组卡片组件
///
/// 遵循 Material Design 3 规范：
/// - 使用 surface 容器颜色
/// - 圆角半径 16dp
/// - 内边距 16dp
/// - 顶部标题区，下方列表项
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
          // 标题
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
          // 列表项
          ...items,
        ],
      ),
    );
  }
}

/// 面板列表项组件
///
/// 遵循 Material Design 3 规范：
/// - 图标使用圆形容器，半径 20dp
/// - 使用 IconButton 风格的交互反馈
/// - 支持可点击与不可点击状态
/// - 右侧显示前进箭头（可点击时）
class _PanelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PanelItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
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
              // 图标容器
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
              // 文本内容
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
              // 右侧箭头
              if (isInteractive) ...[
                const SizedBox(width: 8),
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
