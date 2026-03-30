import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/task_scheduler.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final scheduledTasksProvider = FutureProvider<List<ScheduledTask>>((ref) async {
  return ref.read(systemRepositoryProvider).fetchScheduledTasks();
});

final scheduledTaskBusyIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

void _setBusy(Ref ref, int id, bool busy) {
  final current = {...ref.read(scheduledTaskBusyIdsProvider)};
  if (busy) {
    current.add(id);
  } else {
    current.remove(id);
  }
  ref.read(scheduledTaskBusyIdsProvider.notifier).state = current;
}

final runScheduledTaskProvider = Provider<Future<void> Function(ScheduledTask task)>((ref) {
  return (ScheduledTask task) async {
    _setBusy(ref, task.id, true);
    try {
      await ref.read(systemRepositoryProvider).runScheduledTask(
            id: task.id,
            type: task.type,
            name: task.name,
          );
      ref.invalidate(scheduledTasksProvider);
    } finally {
      _setBusy(ref, task.id, false);
    }
  };
});

final toggleScheduledTaskProvider = Provider<Future<void> Function(ScheduledTask task)>((ref) {
  return (ScheduledTask task) async {
    _setBusy(ref, task.id, true);
    try {
      await ref.read(systemRepositoryProvider).setScheduledTaskEnabled(
            id: task.id,
            enabled: !task.enabled,
          );
      ref.invalidate(scheduledTasksProvider);
    } finally {
      _setBusy(ref, task.id, false);
    }
  };
});
