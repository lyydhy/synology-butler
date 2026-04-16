import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../preferences/providers/preferences_providers.dart';

/// 容器管理设置页。
///
/// 这个页面只承载模块内部配置，避免把容器数据源切换放进全局设置里。
class ContainerManagementSettingsPage extends ConsumerWidget {
  const ContainerManagementSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(containerDataSourceProvider).valueOrNull ?? ContainerDataSourceOption.synology;
    final saveSource = (ContainerDataSourceOption value) => ref.read(containerDataSourceProvider.notifier).save(value);

    return Scaffold(
      appBar: AppBar(title: const Text('容器管理设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '数据源',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _SourceOptionTile(
            title: '群晖 DSM / Container Manager',
            subtitle: '默认数据源，优先接入并作为第一版正式实现。',
            value: ContainerDataSourceOption.synology,
            groupValue: currentSource,
            onChanged: (value) => saveSource(value),
          ),
          const SizedBox(height: 12),
          _SourceOptionTile(
            title: 'dpanel',
            subtitle: '预留扩展入口，当前仍处于开发中。',
            value: ContainerDataSourceOption.dpanel,
            groupValue: currentSource,
            onChanged: (value) => saveSource(value),
            trailing: const _DevelopingBadge(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '说明：切换数据源后，容器 / Compose / 镜像三个分页都会使用新的数据源。\n'
              '第一版先把页面结构、交互和抽象层搭好，后续再逐步接入真实接口。',
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOptionTile extends StatelessWidget {
  const _SourceOptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final ContainerDataSourceOption value;
  final ContainerDataSourceOption groupValue;
  final ValueChanged<ContainerDataSourceOption> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.14)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: groupValue == value ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
              child: groupValue == value
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevelopingBadge extends StatelessWidget {
  const _DevelopingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '开发中',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
      ),
    );
  }
}
