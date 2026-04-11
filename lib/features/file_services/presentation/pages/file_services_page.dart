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
            padding: const EdgeInsets.fromLTRB(16, 12, 24),
            itemCount: allServices.length + 1, // +1 for summary
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SummaryCard(services: services);
              }
              final service = allServices[index - 1];
              final isSmb = service.serviceName == 'SMB';
              final isAfp = service.serviceName == 'AFP';
              return _ServiceCard(
                service: service,
                isSmb: isSmb,
                isAfp: isAfp,
                smbLogEnabled: isSmb ? (transferLogStatus['smb'] ?? false) : false,
                afpLogEnabled: isAfp ? (transferLogStatus['afp'] ?? false) : false,
                onSmbLogChanged: (enabled) async {
                  await ref.read(systemRepositoryProvider).setTransferLogStatus(smbEnabled: enabled);
                  ref.invalidate(transferLogStatusProvider);
                },
                onAfpLogChanged: (enabled) async {
                  await ref.read(systemRepositoryProvider).setTransferLogStatus(afpEnabled: enabled);
                  ref.invalidate(transferLogStatusProvider);
                },
              );
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
  final bool isSmb;
  final bool isAfp;
  final bool smbLogEnabled;
  final bool afpLogEnabled;
  final ValueChanged<bool>? onSmbLogChanged;
  final ValueChanged<bool>? onAfpLogChanged;

  const _ServiceCard({
    required this.service,
    this.isSmb = false,
    this.isAfp = false,
    this.smbLogEnabled = false,
    this.afpLogEnabled = false,
    this.onSmbLogChanged,
    this.onAfpLogChanged,
  });

  @override
  ConsumerState<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends ConsumerState<_ServiceCard> {
  bool _loading = false;
  bool _smbLogLoading = false;
  bool _afpLogLoading = false;

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
          // SMB 传输日志控制（与 dsm_helper 一致：服务启用后显示开关，启用后显示"日志设置"和"查看日志"）
          if (widget.isSmb && service.enabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _LogToggleRow(
              title: l10n.smbTransferLog,
              subtitle: l10n.smbTransferLogSubtitle,
              value: widget.smbLogEnabled,
              loading: _smbLogLoading,
              onChanged: (value) async {
                if (_smbLogLoading) return;
                setState(() => _smbLogLoading = true);
                try {
                  widget.onSmbLogChanged?.call(value);
                  if (mounted) Toast.success(value ? l10n.smbTransferLogEnabled : l10n.smbTransferLogDisabled);
                } catch (e) {
                  if (mounted) Toast.error('设置失败: $e');
                } finally {
                  if (mounted) setState(() => _smbLogLoading = false);
                }
              },
            ),
            if (widget.smbLogEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TransferLogLevelPage(
                              protocol: 'cifs',
                              protocolName: 'SMB',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(l10n.setLogLevel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 跳转到日志查看页
                        Toast.show('日志查看功能开发中');
                      },
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('查看日志'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          // AFP 传输日志控制
          if (widget.isAfp && service.enabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _LogToggleRow(
              title: l10n.afpTransferLog,
              subtitle: l10n.afpTransferLogSubtitle,
              value: widget.afpLogEnabled,
              loading: _afpLogLoading,
              onChanged: (value) async {
                if (_afpLogLoading) return;
                setState(() => _afpLogLoading = true);
                try {
                  widget.onAfpLogChanged?.call(value);
                  if (mounted) Toast.success(value ? l10n.afpTransferLogEnabled : l10n.afpTransferLogDisabled);
                } catch (e) {
                  if (mounted) Toast.error('设置失败: $e');
                } finally {
                  if (mounted) setState(() => _afpLogLoading = false);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _LogToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _LogToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
            onChanged: onChanged,
          ),
      ],
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

