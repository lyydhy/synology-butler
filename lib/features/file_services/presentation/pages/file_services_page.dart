import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/file_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/file_services_providers.dart';
import 'transfer_log_level_page.dart';

class FileServicesPage extends ConsumerWidget {
  const FileServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(fileServicesProvider);
    final transferLogAsync = ref.watch(transferLogStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fileServicesTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () {
              ref.invalidate(fileServicesProvider);
              ref.invalidate(transferLogStatusProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: l10n.loadFailed(error),
          message: '$error',
          onRetry: () {
            ref.invalidate(fileServicesProvider);
            ref.invalidate(transferLogStatusProvider);
          },
          actionLabel: l10n.retry,
        ),
        data: (services) {
          final allServices = services.allServices;
          if (allServices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.dns_outlined, size: 52),
                    const SizedBox(height: 12),
                    Text(l10n.noFileServices),
                  ],
                ),
              ),
            );
          }

          final transferLogStatus = transferLogAsync.valueOrNull ?? {'smb': false, 'afp': false};

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: allServices.length + 2, // +1 for summary, +1 for transfer log
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SummaryCard(services: services);
              }
              if (index == allServices.length + 1) {
                return _TransferLogCard(
                  smbEnabled: transferLogStatus['smb'] ?? false,
                  afpEnabled: transferLogStatus['afp'] ?? false,
                  smbServiceEnabled: services.smb?.enabled ?? false,
                  afpServiceEnabled: services.afp?.enabled ?? false,
                );
              }
              final service = allServices[index - 1];
              return _ServiceCard(service: service);
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final FileServicesModel services;

  const _SummaryCard({required this.services});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledCount = services.enabledCount;
    final totalCount = services.allServices.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.storage_rounded, color: theme.colorScheme.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fileServicesStatusSummary,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.fileServicesEnabledCount(enabledCount, totalCount),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends ConsumerStatefulWidget {
  final FileServiceStatus service;

  const _ServiceCard({required this.service});

  @override
  ConsumerState<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends ConsumerState<_ServiceCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;
    final color = service.enabled ? Colors.green : Colors.grey;

    IconData icon;
    switch (service.serviceName) {
      case 'SMB':
        icon = Icons.folder_shared_rounded;
        break;
      case 'NFS':
        icon = Icons.share_rounded;
        break;
      case 'FTP':
        icon = Icons.cloud_upload_rounded;
        break;
      case 'AFP':
        icon = Icons.apple_rounded;
        break;
      case 'SFTP':
        icon = Icons.lock_rounded;
        break;
      default:
        icon = Icons.dns_rounded;
    }

    // 从 extraInfo 获取更多信息
    final workgroup = service.extraInfo['workgroup'] as String?;
    final nfsV4Domain = service.extraInfo['nfs_v4_domain'] as String?;
    final ftpsEnabled = service.extraInfo['enable_ftps'] as bool?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.enabled ? l10n.fileServiceEnabled : l10n.fileServiceDisabled,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              Switch(
                value: service.enabled,
                onChanged: _loading ? null : (value) async {
                  setState(() => _loading = true);
                  try {
                    await ref.read(systemRepositoryProvider).setFileServiceEnabled(
                          serviceName: service.serviceName,
                          enabled: value,
                        );
                    ref.invalidate(fileServicesProvider);
                    if (context.mounted) {
                      Toast.success('${service.serviceName} ${value ? l10n.fileServiceEnabled : l10n.fileServiceDisabled}');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Toast.error('操作失败: $e');
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
              ),
            ],
          ),
          // 显示详细信息
          if (service.version != null || service.port != null || workgroup != null && workgroup.isNotEmpty || nfsV4Domain != null && nfsV4Domain.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (service.version != null)
                  _MetaItem(label: l10n.serviceVersion, value: service.version!),
                if (service.port != null)
                  _MetaItem(label: l10n.servicePort, value: service.port.toString()),
                if (workgroup != null && workgroup.isNotEmpty)
                  _MetaItem(label: l10n.workgroup, value: workgroup),
                if (nfsV4Domain != null && nfsV4Domain.isNotEmpty)
                  _MetaItem(label: l10n.nfsV4Domain, value: nfsV4Domain),
                if (ftpsEnabled == true)
                  _MetaItem(label: l10n.ftpsEnabled, value: l10n.enabled),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label：',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TransferLogCard extends ConsumerStatefulWidget {
  final bool smbEnabled;
  final bool afpEnabled;
  final bool smbServiceEnabled;
  final bool afpServiceEnabled;

  const _TransferLogCard({
    required this.smbEnabled,
    required this.afpEnabled,
    required this.smbServiceEnabled,
    required this.afpServiceEnabled,
  });

  @override
  ConsumerState<_TransferLogCard> createState() => _TransferLogCardState();
}

class _TransferLogCardState extends ConsumerState<_TransferLogCard> {
  late bool _smbLogEnabled;
  late bool _afpLogEnabled;
  bool _smbLoading = false;
  bool _afpLoading = false;

  @override
  void initState() {
    super.initState();
    _smbLogEnabled = widget.smbEnabled;
    _afpLogEnabled = widget.afpEnabled;
  }

  @override
  void didUpdateWidget(_TransferLogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.smbEnabled != widget.smbEnabled) {
      _smbLogEnabled = widget.smbEnabled;
    }
    if (oldWidget.afpEnabled != widget.afpEnabled) {
      _afpLogEnabled = widget.afpEnabled;
    }
  }

  Future<void> _toggleSmbLog(bool value) async {
    if (_smbLoading) return;
    setState(() => _smbLoading = true);
    try {
      await ref.read(systemRepositoryProvider).setTransferLogStatus(smbEnabled: value);
      setState(() => _smbLogEnabled = value);
      if (mounted) {
        Toast.success(value ? l10n.smbTransferLogEnabled : l10n.smbTransferLogDisabled);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('设置失败: $e');
      }
    } finally {
      if (mounted) setState(() => _smbLoading = false);
    }
  }

  Future<void> _toggleAfpLog(bool value) async {
    if (_afpLoading) return;
    setState(() => _afpLoading = true);
    try {
      await ref.read(systemRepositoryProvider).setTransferLogStatus(afpEnabled: value);
      setState(() => _afpLogEnabled = value);
      if (mounted) {
        Toast.success(value ? l10n.afpTransferLogEnabled : l10n.afpTransferLogDisabled);
      }
    } catch (e) {
      if (mounted) {
        Toast.error('设置失败: $e');
      }
    } finally {
      if (mounted) setState(() => _afpLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.transferLogTitle,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.transferLogSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // SMB 传输日志
          _buildLogToggle(
            context: context,
            title: l10n.smbTransferLog,
            subtitle: l10n.smbTransferLogSubtitle,
            value: _smbLogEnabled,
            loading: _smbLoading,
            serviceEnabled: widget.smbServiceEnabled,
            onChanged: _toggleSmbLog,
            onSettingsPressed: widget.smbServiceEnabled
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TransferLogLevelPage(
                          protocol: 'cifs',
                          protocolName: 'SMB',
                        ),
                      ),
                    );
                  }
                : null,
          ),
          const Divider(height: 24),
          // AFP 传输日志
          _buildLogToggle(
            context: context,
            title: l10n.afpTransferLog,
            subtitle: l10n.afpTransferLogSubtitle,
            value: _afpLogEnabled,
            loading: _afpLoading,
            serviceEnabled: widget.afpServiceEnabled,
            onChanged: _toggleAfpLog,
          ),
        ],
      ),
    );
  }

  Widget _buildLogToggle({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required bool loading,
    required bool serviceEnabled,
    required ValueChanged<bool> onChanged,
    VoidCallback? onSettingsPressed,
  }) {
    final theme = Theme.of(context);
    final bool canToggle = serviceEnabled;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: canToggle ? null : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          canToggle ? subtitle : l10n.needEnableServiceFirst,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: canToggle ? 1 : 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onSettingsPressed != null)
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22),
                      onPressed: onSettingsPressed,
                      tooltip: l10n.setLogLevel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Switch(
            value: value,
            onChanged: canToggle ? onChanged : null,
          ),
      ],
    );
  }
}
