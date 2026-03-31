import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/external_device.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final externalDevicesProvider = FutureProvider<List<ExternalDevice>>((ref) async {
  return ref.read(systemRepositoryProvider).fetchExternalDevices();
});

final externalDeviceBusyIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

void _setBusy(Ref ref, String id, bool busy) {
  final current = {...ref.read(externalDeviceBusyIdsProvider)};
  if (busy) {
    current.add(id);
  } else {
    current.remove(id);
  }
  ref.read(externalDeviceBusyIdsProvider.notifier).state = current;
}

final ejectExternalDeviceProvider = Provider<Future<void> Function(ExternalDevice device)>((ref) {
  return (ExternalDevice device) async {
    _setBusy(ref, device.id, true);
    try {
      await ref.read(systemRepositoryProvider).ejectExternalDevice(id: device.id, bus: device.bus);
      ref.invalidate(externalDevicesProvider);
    } finally {
      _setBusy(ref, device.id, false);
    }
  };
});
