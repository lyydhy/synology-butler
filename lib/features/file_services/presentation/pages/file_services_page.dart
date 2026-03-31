import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/file_service.dart';
import '../providers/file_services_providers.dart';

class FileServicesPage extends ConsumerWidget {
  const FileServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(fileServicesProvider);
    

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fileServicesTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(fileServicesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(fileServicesProvider),
          actionLabel: '重新加载',
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: allServices.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SummaryCard(services: services);
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
                  '文件服务状态',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '已启用 $enabledCount / $totalCount 项服务',
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

class _ServiceCard extends StatelessWidget {
  final FileServiceStatus service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: Icon(icon, color: color),
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
                      service.enabled ? '已启用' : '未启用',
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  service.enabled ? 'ON' : 'OFF',
                  style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (service.version != null || service.port != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (service.version != null)
                  _MetaItem(label: '版本', value: service.version!),
                if (service.port != null)
                  _MetaItem(label: '端口', value: service.port.toString()),
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
