import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/l10n.dart';
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
        title: Text(l10n.sharingLinksTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: l10n.sharingLinksClearInvalid,
            onPressed: () => _showClearInvalidSheet(context, ref),
          ),
        ],
      ),
      body: linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(shareLinksProvider),
        ),
        data: (links) {
          if (links.isEmpty) {
            return const _EmptyView();
          }
          return _LinksListView(links: links);
        },
      ),
    );
  }

  Future<void> _showClearInvalidSheet(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.cleaning_services_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.sharingLinksClearInvalid,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sharingLinksClearInvalidConfirm,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.confirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(clearInvalidShareLinksProvider)();
      Toast.success(l10n.sharingLinksClearSuccess);
    } catch (e) {
      Toast.error(l10n.sharingLinksClearFailed(e.toString()));
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              l10n.sharingLinksEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sharingLinksEmptyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            Text(l10n.sharingLinksLoadFailed, style: theme.textTheme.titleMedium),
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
              label: Text(l10n.sharingLinksRetry),
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: links.length,
      itemBuilder: (context, index) {
        final link = links[index];
        return _ShareLinkCard(link: link);
      },
    );
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
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
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.person_outline,
                    label: link.linkOwner,
                    flex: 1,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.folder_outlined,
                    label: link.path.split('/').where((e) => e.isNotEmpty).lastOrNull ?? '/',
                    flex: 2,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (link.dateExpired != null && link.dateExpired!.isNotEmpty)
                    _ExpireBadge(
                      icon: Icons.event,
                      label: _formatDate(link.dateExpired!),
                      color: Colors.blue,
                    ),
                  if (link.dateExpired != null && link.dateExpired!.isNotEmpty && link.expireTimes > 0)
                    const SizedBox(width: 8),
                  if (link.expireTimes > 0)
                    _ExpireBadge(
                      icon: Icons.repeat,
                      label: l10n.sharingLinksAccessCountRemaining(link.expireTimes),
                      color: Colors.orange,
                    )
                  else
                    _ExpireBadge(
                      icon: Icons.all_inclusive,
                      label: l10n.sharingLinksPermanent,
                      color: Colors.green,
                    ),
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: l10n.sharingLinksCopied,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link.url));
                      Toast.success(l10n.sharingLinksCopied);
                    },
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.sharingLinksDelete,
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
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.delete_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.sharingLinksDelete,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sharingLinksDeleteConfirm(link.name),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.deleteConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(deleteShareLinksProvider)([link.id]);
      Toast.success(l10n.sharingLinksDeleted);
    } catch (e) {
      Toast.error(l10n.sharingLinksDeleteFailed(e.toString()));
    }
  }

  Future<void> _showEditSheet(BuildContext context, WidgetRef ref) async {
    int expireTimes = link.expireTimes;
    DateTime? dateAvailable;
    DateTime? dateExpired;
    if (link.dateAvailable != null && link.dateAvailable!.isNotEmpty) {
      dateAvailable = DateTime.tryParse(link.dateAvailable!);
    }
    if (link.dateExpired != null && link.dateExpired!.isNotEmpty) {
      dateExpired = DateTime.tryParse(link.dateExpired!);
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        l10n.sharingLinksEdit,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Security hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.sharingLinksSecurityHint,
                            style: const TextStyle(fontSize: 13, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // File name
                  Text(
                    link.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link.url,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 28),

                  // Access count
                  Text(
                    l10n.sharingLinksAccessCount,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _ExpireTimesSelector(
                    value: expireTimes,
                    onChanged: (v) => setState(() => expireTimes = v),
                  ),
                  const SizedBox(height: 24),

                  // Available date
                  Text(
                    l10n.sharingLinksAvailableDate,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _DateTimePicker(
                    value: dateAvailable,
                    onChanged: (v) => setState(() => dateAvailable = v),
                  ),
                  const SizedBox(height: 24),

                  // Expire date
                  Text(
                    l10n.sharingLinksExpireDate,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _DateTimePicker(
                    value: dateExpired,
                    onChanged: (v) => setState(() => dateExpired = v),
                  ),
                  const SizedBox(height: 32),

                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != true) return;

    try {
      await ref.read(editShareLinkProvider)(
        link.id,
        link.url,
        link.path,
        dateAvailable: dateAvailable?.toIso8601String(),
        dateExpired: dateExpired?.toIso8601String(),
        expireTimes: expireTimes,
      );
      Toast.success(l10n.sharingLinksSaveSuccess);
    } catch (e) {
      Toast.error(l10n.sharingLinksSaveFailed(e.toString()));
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
        label = l10n.sharingLinksStatusValid;
        icon = Icons.check_circle_outline;
        break;
      case 'expired':
        color = Colors.grey;
        label = l10n.sharingLinksStatusExpired;
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
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
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
    return Row(
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
        const SizedBox(width: 16),
        Text(
          value == 0 ? l10n.sharingLinksAccessCountUnlimited : l10n.sharingLinksAccessCountRemaining(value),
          style: TextStyle(fontSize: 13, color: value == 0 ? Colors.green : Colors.orange),
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
                        : l10n.sharingLinksNoLimit,
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
