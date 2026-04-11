import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/l10n.dart';
import '../../../../core/utils/toast.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../domain/entities/external_device.dart';
import '../providers/external_devices_providers.dart';

class ExternalDevicesPage extends ConsumerWidget {
  const ExternalDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(externalDevicesProvider);
    final busyIds = ref.watch(externalDeviceBusyIdsProvider);
    

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.externalDevicesTitle),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(externalDevicesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: '外接设备加载失败',
          message: '$error',
          onRetry: () => ref.invalidate(externalDevicesProvider),
          actionLabel: l10n.reload,
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.usb_off_rounded, size: 52),
                    const SizedBox(height: 12),
                    Text(l10n.noExternalDevices),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final busy = busyIds.contains(device.id);
              return _DeviceCard(
                device: device,
                busy: busy,
                onEject: () async {
                  try {
                    await ref.read(ejectExternalDeviceProvider)(device);
                    Toast.success(l10n.ejectSubmitted);
                  } catch (error) {
                    Toast.error('${l10n.ejectFailed}：$error');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ExternalDevice device;
  final bool busy;
  
  final Future<void> Function() onEject;

  const _DeviceCard({required this.device, required this.busy,  required this.onEject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = device.bus == 'esata' ? Colors.deepPurple : Colors.blue;
    final title = device.name.isNotEmpty ? device.name : (device.model.isNotEmpty ? device.model : l10n.unnamedDevice);

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
                child: Icon(device.bus == 'esata' ? Icons.storage_rounded : Icons.usb_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      [device.vendor, device.model].where((item) => item.isNotEmpty).join(' · ').ifEmpty(l10n.unrecognizedModel),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  device.bus.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetaRow(label: '状态', value: device.status.isEmpty ? '-' : device.status),
          _MetaRow(label: '卷数量', value: '${device.volumes.length}'),
          if (device.volumes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...device.volumes.map(
              (volume) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(volume.name.isEmpty ? '未命名卷' : volume.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${l10n.fileSystem}：${volume.fileSystem.isEmpty ? '-' : volume.fileSystem}'),
                      Text('${l10n.mountPath}：${volume.mountPath.isEmpty ? '-' : volume.mountPath}'),
                      if (volume.totalSizeText.isNotEmpty || volume.usedSizeText.isNotEmpty)
                        Text('${l10n.capacity}：${volume.usedSizeText.isEmpty ? '-' : volume.usedSizeText} / ${volume.totalSizeText.isEmpty ? '-' : volume.totalSizeText}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy || !device.canEject || device.id.isEmpty ? null : onEject,
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.eject_rounded),
              label: Text(device.canEject ? l10n.ejectDevice : l10n.currentlyNotEjectable),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
          children: [
            TextSpan(
              text: '$label：',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
