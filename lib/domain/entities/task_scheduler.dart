class ScheduledTaskRecord {
  final String startTime;
  final String result;

  const ScheduledTaskRecord({
    required this.startTime,
    required this.result,
  });
}

class ScheduledTask {
  final int id;
  final String name;
  final String owner;
  final String type;
  final bool enabled;
  final bool running;
  final String nextTriggerTime;
  final List<ScheduledTaskRecord> records;

  const ScheduledTask({
    required this.id,
    required this.name,
    required this.owner,
    required this.type,
    required this.enabled,
    required this.running,
    required this.nextTriggerTime,
    this.records = const [],
  });
}
