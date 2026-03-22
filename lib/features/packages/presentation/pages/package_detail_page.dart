import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/package_volume.dart';
import '../providers/package_providers.dart';

class PackageDetailPage extends ConsumerWidget {
  final PackageItem item;

  const PackageDetailPage({super.key, required this.item});

  Future<String?> _pickVolume(BuildContext context, WidgetRef ref) async {
    final volumes = await ref.read(packageVolumesProvider.future);
    if (volumes.isEmpty || !context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('选择安装位置'),
                subtitle: Text('请选择套件安装的存储卷'),
              ),
              for (final volume in volumes) _DetailVolumeTile(volume: volume),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmQueueImpact(BuildContext context, WidgetRef ref) async {
    final impact = ref.read(packagePendingQueueImpactProvider);
    if (impact == null || impact.pausedPackages.isEmpty) {
      return true;
    }

    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认更新影响'),
            content: Text(
              '继续安装/更新 ${item.displayName} 时，以下套件可能会被暂停：\n\n${impact.pausedPackages.join('、')}',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('继续')),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installStatus = ref.watch(packageInstallStatusProvider);
    final installingId = ref.watch(packageInstallingProvider);
    final isInstallingThis = installingId == item.id;

    return Scaffold(
      appBar: AppBar(title: Text(item.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.apps_rounded, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _DetailChip(
                                  text: item.canUpdate ? '可更新' : item.isInstalled ? '已安装' : '未安装',
                                  color: item.canUpdate
                                      ? Colors.orange
                                      : item.isInstalled
                                          ? Colors.blue
                                          : Colors.grey,
                                ),
                                if (item.isRunning)
                                  const _DetailChip(text: '运行中', color: Colors.green),
                                if (item.isBeta)
                                  const _DetailChip(text: 'Beta', color: Colors.deepPurple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(item.description.isEmpty ? '暂无描述' : item.description),
                  const SizedBox(height: 20),
                  _InfoRow(label: '商店版本', value: item.version),
                  if (item.installedVersion != null && item.installedVersion!.isNotEmpty)
                    _InfoRow(label: '已安装版本', value: item.installedVersion!),
                  if (item.status != null && item.status!.isNotEmpty) _InfoRow(label: '状态', value: item.status!),
                  if (item.distributor != null && item.distributor!.isNotEmpty)
                    _InfoRow(label: '发行方', value: item.distributor!),
                  if (item.maintainer != null && item.maintainer!.isNotEmpty)
                    _InfoRow(label: '维护者', value: item.maintainer!),
                  if (item.installPath != null && item.installPath!.isNotEmpty)
                    _InfoRow(label: '安装路径', value: item.installPath!),
                ],
              ),
            ),
          ),
          if (item.screenshots.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('截图', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => Container(
                  width: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        item.screenshots[index],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (installStatus != null && installStatus.isNotEmpty)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('当前任务：$installStatus')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (item.isInstalled && !item.isRunning)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(packageStartProvider)(item);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已发送启动请求：${item.displayName}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('启动'),
                ),
              if (item.isInstalled && item.isRunning)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(packageStopProvider)(item);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已发送停止请求：${item.displayName}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('停止'),
                ),
              if (item.isInstalled)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认卸载'),
                            content: Text('确定要卸载 ${item.displayName} 吗？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
                              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('卸载')),
                            ],
                          ),
                        ) ??
                        false;
                    if (!confirmed) return;

                    await ref.read(packageUninstallProvider)(item);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('卸载'),
                ),
              FilledButton.icon(
                onPressed: (item.isInstalled && !item.canUpdate) || isInstallingThis
                    ? null
                    : () async {
                        final volumePath = await _pickVolume(context, ref);
                        if (volumePath == null || volumePath.isEmpty) return;

                        await ref.read(packagePrepareInstallProvider)(item);
                        if (!context.mounted) return;

                        final confirmed = await _confirmQueueImpact(context, ref);
                        if (!confirmed) return;

                        try {
                          await ref.read(packageInstallProvider)(item, volumePath);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${item.displayName} 安装/更新任务已完成或已提交')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('套件安装失败：$e')),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.system_update_alt_rounded),
                label: Text(
                  isInstallingThis
                      ? '进行中'
                      : item.canUpdate
                          ? '更新'
                          : item.isInstalled
                              ? '已安装'
                              : '安装',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String text;
  final Color color;

  const _DetailChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _DetailVolumeTile extends StatelessWidget {
  final PackageVolume volume;

  const _DetailVolumeTile({required this.volume});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.storage_rounded),
      title: Text(volume.displayName.isEmpty ? volume.path : volume.displayName),
      subtitle: Text(
        [
          if (volume.description.isNotEmpty) volume.description,
          if (volume.fsType.isNotEmpty) volume.fsType,
          if (volume.freeBytes != null && volume.freeBytes!.isNotEmpty) '可用 ${volume.freeBytes}',
        ].join(' · '),
      ),
      onTap: () => Navigator.of(context).pop(volume.path),
    );
  }
}
