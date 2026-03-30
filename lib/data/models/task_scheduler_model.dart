class ScheduledTaskRecordModel {
  final String startTime;
  final String result;

  const ScheduledTaskRecordModel({
    required this.startTime,
    required this.result,
  });
}

class ScheduledTaskModel {
  final int id;
  final String name;
  final String owner;
  final String type;
  final bool enabled;
  final bool running;
  final String nextTriggerTime;
  final List<ScheduledTaskRecordModel> records;

  const ScheduledTaskModel({
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
