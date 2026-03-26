import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_surface_card.dart';
import '../../../../core/widgets/sliding_tab_bar.dart';
import '../../../../domain/entities/package_item.dart';
import '../../../../domain/entities/package_volume.dart';
import '../../../auth/presentation/providers/current_connection_readers.dart';
import '../providers/package_providers.dart';

/// 套件中心首页。
///
/// 使用通用 SlidingTabBar + TabBarView 统一页签交互，
/// 安装流程状态仍通过 provider 在列表页和详情页之间共享。
class PackagesPage extends ConsumerStatefulWidget {
  const PackagesPage({super.key});

  @override
  ConsumerState<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends ConsumerState<PackagesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 根据页签下标过滤展示的套件列表。
  List<PackageItem> _filterItems(List<PackageItem> items, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return items.where((item) => item.isInstalled).toList();
      case 2:
        return items.where((item) => item.canUpdate).toList();
      default:
        return items;
    }
  }

  /// 刷新套件列表相关数据。
  void _refreshPackages() {
    ref.invalidate(storePackagesProvider);
    ref.invalidate(installedPackagesProvider);
    ref.invalidate(mergedPackagesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(activeServerProvider);
    final session = ref.watch(activeSessionProvider);
    final packagesAsync = ref.watch(mergedPackagesProvider);
    final installState = ref.watch(packageInstallStateProvider);
    final installStatus = installState.statusText;

    if (server == null || session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('套件中心')),
        body: const Center(child: Text('当前没有可用会话，请先登录 NAS')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('套件中心'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _refreshPackages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SlidingTabBar(
              tabController: _tabController,
              height: 54,
              iconSize: 18,
              fontSize: 13,
              tabs: const [
                SlidingTabItem(icon: Icons.apps_rounded, label: '全部'),
                SlidingTabItem(icon: Icons.check_circle_outline_rounded, label: '已安装'),
                SlidingTabItem(icon: Icons.system_update_alt_rounded, label: '可更新'),
              ],
            ),
          ),
          if (installStatus != null && installStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('套件任务：$installStatus')),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: packagesAsync.when(
              data: (items) => TabBarView(
                controller: _tabController,
                children: [
                  _PackageListView(items: _filterItems(items, 0)),
                  _PackageListView(items: _filterItems(items, 1)),
                  _PackageListView(items: _filterItems(items, 2)),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('套件列表加载失败\n$error', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageListView extends StatelessWidget {
  const _PackageListView({required this.items});

  final List<PackageItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无套件数据'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _PackageCard(item: items[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _PackageCard extends ConsumerWidget {
  const _PackageCard({required this.item});

  final PackageItem item;

  /// 弹出底部面板，让用户选择安装卷。
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
                subtitle: Text('先选择套件要安装到哪个存储卷'),
              ),
              for (final volume in volumes) _VolumeTile(volume: volume),
            ],
          ),
        );
      },
    );
  }

  /// 当前套件状态对应的标签颜色。
  Color _statusColor(BuildContext context) {
    if (item.canUpdate) return Colors.orange;
    if (item.isRunning) return Colors.green;
    if (item.isInstalled) return Theme.of(context).colorScheme.primary;
    return Colors.grey;
  }

  /// 当前套件状态对应的标签文案。
  String _statusText() {
    if (item.canUpdate) return '可更新';
    if (item.isRunning) return '运行中';
    if (item.isInstalled) return '已安装';
    return '未安装';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installState = ref.watch(packageInstallStateProvider);
    final isInstallingThis = installState.isInstalling(item.id);

    return AppSurfaceCard(
      onTap: () => context.push('/packages/detail', extra: item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.apps_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (item.isBeta)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('Beta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description.isEmpty ? '暂无描述' : item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TagChip(text: _statusText(), color: _statusColor(context)),
                            _TagChip(text: '商店版本 ${item.version}', color: Colors.blue),
                            if (item.installedVersion != null && item.installedVersion!.isNotEmpty)
                              _TagChip(text: '已装 ${item.installedVersion}', color: Colors.teal),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
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
                  if (item.isInstalled) const SizedBox(width: 10),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已发送卸载请求：${item.displayName}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('卸载'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: (item.isInstalled && !item.canUpdate) || isInstallingThis
                        ? null
                        : () async {
                            final volumePath = await _pickVolume(context, ref);
                            if (volumePath == null || volumePath.isEmpty) return;

                            await ref.read(packagePrepareInstallProvider)(item);
                            if (!context.mounted) return;

                            final impact = ref.read(packageInstallStateProvider).pendingQueueImpact;
                            if (impact != null && impact.pausedPackages.isNotEmpty) {
                              final confirmed = await showDialog<bool>(
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
                                  ) ??
                                  false;
                              if (!confirmed) return;
                            }

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
                    child: Text(
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

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({required this.volume});

  final PackageVolume volume;

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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
