import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../files/presentation/providers/file_providers.dart';
import '../../../../domain/entities/share_link.dart';

class SharingLinksPage extends ConsumerWidget {
  const SharingLinksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(shareLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享链接管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: '清除无效链接',
            onPressed: () => _showClearInvalidDialog(context, ref),
          ),
        ],
      ),
      body: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(shareLinksProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (links) {
          if (links.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无分享链接', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(shareLinksProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: links.length,
              itemBuilder: (context, index) {
                final link = links[index];
                return _ShareLinkCard(link: link);
              },
            ),
          );
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清除无效链接')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除失败: $e')),
        );
      }
    }
  }
}

class _ShareLinkCard extends ConsumerWidget {
  const _ShareLinkCard({required this.link});

  final ShareLinkResult link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  link.isFolder ? Icons.folder : Icons.insert_drive_file,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    link.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: '复制链接',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('链接已复制'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '编辑',
                  onPressed: () => _showEditDialog(context, ref),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                  tooltip: '删除',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              link.url,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    link.path,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (link.expireTimes > 0) ...[
                  Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '有效期: ${link.expireTimes}次',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                  ),
                ] else ...[
                  Icon(Icons.schedule, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '永久有效',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                  ),
                ],
                const Spacer(),
                Text(
                  '所有者: ${link.linkOwner}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('安全共享请到 Web 界面操作', style: TextStyle(fontSize: 12, color: Colors.orange)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(link.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(link.url, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
              const SizedBox(height: 16),
              _ExpireTimesSelector(
                value: expireTimes,
                onChanged: (v) => setState(() => expireTimes = v),
              ),
              const SizedBox(height: 16),
              const Text('有效期截止日期'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dateExpired ?? now.add(const Duration(days: 7)),
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dateExpired ?? now),
                          );
                          setState(() {
                            dateExpired = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time?.hour ?? 23,
                              time?.minute ?? 59,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              dateExpired != null
                                  ? '${dateExpired!.year}-${dateExpired!.month.toString().padLeft(2, '0')}-${dateExpired!.day.toString().padLeft(2, '0')} ${dateExpired!.hour.toString().padLeft(2, '0')}:${dateExpired!.minute.toString().padLeft(2, '0')}'
                                  : '不限制',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (dateExpired != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => dateExpired = null),
                    ),
                  ],
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}

/// 有效期次数选择器（创建和编辑共用）
class _ExpireTimesSelector extends StatelessWidget {
  const _ExpireTimesSelector({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('有效期次数（0 = 无限）'),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$value', style: const TextStyle(fontSize: 16)),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value == 0 ? '永久有效' : '剩余 $value 次',
          style: TextStyle(color: value == 0 ? Colors.green : Colors.orange, fontSize: 12),
        ),
      ],
    );
  }
}
