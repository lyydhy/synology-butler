import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/toast.dart';
import '../../../files/presentation/providers/file_providers.dart';
import '../../../../domain/entities/share_link.dart';

class SharingLinksPage extends ConsumerWidget {
  const SharingLinksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(shareLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享链接'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: '清除无效链接',
            onPressed: () => _showClearInvalidDialog(context, ref),
          ),
        ],
      ),
      body: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(error: error.toString(), onRetry: () => ref.invalidate(shareLinksProvider)),
        data: (links) {
          if (links.isEmpty) {
            return const _EmptyView();
          }
          return _LinksListView(links: links);
        },
      ),
    );
  }

  Future<void> _showClearInvalidDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除无效链接'),
        content: const Text('确定要清除所有无效的分享链接吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(clearInvalidShareLinksProvider)();
      Toast.success('已清除无效链接');
    } catch (e) {
      Toast.error('清除失败: $e');
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.link_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无分享链接',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在文件页面创建分享链接后可在此管理',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinksListView extends StatelessWidget {
  const _LinksListView({required this.links});

  final List<ShareLinkResult> links;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Will be handled by invalidating the provider
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];
          return _ShareLinkCard(link: link);
        },
      ),
    );
  }
}

class _ShareLinkCard extends ConsumerWidget {
  const _ShareLinkCard({required this.link});

  final ShareLinkResult link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpired = link.status == 'expired';
    final isValid = link.status == 'valid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      link.isFolder ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          link.url,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: link.status),
                ],
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
              const SizedBox(height: 12),

              // Info row
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.folder_outlined,
                    label: link.path.split('/').where((e) => e.isNotEmpty).lastOrNull ?? '/',
                    flex: 2,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.person_outline,
                    label: link.linkOwner,
                    flex: 1,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Expire info
              Row(
                children: [
                  if (link.dateExpired != null && link.dateExpired!.isNotEmpty) ...[
                    _ExpireBadge(
                      icon: Icons.event,
                      label: _formatDate(link.dateExpired!),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (link.expireTimes > 0)
                    _ExpireBadge(
                      icon: Icons.repeat,
                      label: '${link.expireTimes}次',
                      color: Colors.orange,
                    )
                  else
                    _ExpireBadge(
                      icon: Icons.all_inclusive,
                      label: '永久',
                      color: Colors.green,
                    ),
                  const Spacer(),
                  // Action buttons
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: '复制链接',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link.url));
                      Toast.success('链接已复制');
                    },
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: '删除',
                    color: theme.colorScheme.error,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除分享链接'),
        content: Text('确定要删除 "${link.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(deleteShareLinksProvider)([link.id]);
      Toast.success('已删除');
    } catch (e) {
      Toast.error('删除失败: $e');
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    int expireTimes = link.expireTimes;
    DateTime? dateExpired;
    if (link.dateExpired != null && link.dateExpired!.isNotEmpty) {
      dateExpired = DateTime.tryParse(link.dateExpired!);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑分享链接'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('安全共享请到 Web 界面操作', style: TextStyle(fontSize: 13, color: Colors.orange)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(link.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(link.url, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                const SizedBox(height: 20),
                _ExpireTimesSelector(
                  value: expireTimes,
                  onChanged: (v) => setState(() => expireTimes = v),
                ),
                const SizedBox(height: 16),
                const Text('有效期截止日期', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _DateTimePicker(
                  value: dateExpired,
                  onChanged: (v) => setState(() => dateExpired = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await ref.read(editShareLinkProvider)(
        link.id,
        link.url,
        link.path,
        dateExpired: dateExpired?.toIso8601String(),
        expireTimes: expireTimes,
      );
      Toast.success('已保存');
    } catch (e) {
      Toast.error('保存失败: $e');
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'valid':
        color = Colors.green;
        label = '有效';
        icon = Icons.check_circle_outline;
        break;
      case 'expired':
        color = Colors.grey;
        label = '已过期';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.orange;
        label = status;
        icon = Icons.warning_amber_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.flex = 1});

  final IconData icon;
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpireBadge extends StatelessWidget {
  const _ExpireBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ExpireTimesSelector extends StatelessWidget {
  const _ExpireTimesSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('访问次数', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 64,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value == 0 ? '∞' : '$value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              onPressed: () => onChanged(value + 1),
            ),
            const SizedBox(width: 12),
            Text(
              value == 0 ? '不限次数' : '剩余 $value 次',
              style: TextStyle(fontSize: 12, color: value == 0 ? Colors.green : Colors.orange),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.value, required this.onChanged});

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickDateTime(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    value != null
                        ? '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                        : '不限制',
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (value != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => onChanged(null),
            tooltip: '清除',
          ),
        ],
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(value ?? now),
      );
      onChanged(DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? 23,
        time?.minute ?? 59,
      ));
    }
  }
}
