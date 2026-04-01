/// 开关机计划任务
class PowerScheduleTask {
  final String id;
  final bool enabled;
  final int hour;
  final int minute;
  final List<int> weekdays; // 0=周日, 1=周一, ..., 6=周六
  final PowerScheduleType type;

  const PowerScheduleTask({
    required this.id,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.type,
  });

  factory PowerScheduleTask.fromJson(Map<String, dynamic> json, PowerScheduleType type) {
    String weekdaysStr = json['weekdays']?.toString() ?? '0,1,2,3,4,5,6';
    List<int> weekdays = weekdaysStr.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();

    return PowerScheduleTask(
      id: '${type.name}_${json['hour']}_${json['min']}_$weekdaysStr',
      enabled: json['enabled'] as bool? ?? true,
      hour: json['hour'] as int? ?? 0,
      minute: json['min'] as int? ?? 0,
      weekdays: weekdays,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hour': hour,
      'min': minute,
      'weekdays': weekdays.join(','),
    };
  }

  String get timeDisplay {
    final hourStr = hour.toString().padLeft(2, '0');
    final minStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr';
  }

  String get weekdaysDisplay {
    const dayNames = ['日', '一', '二', '三', '四', '五', '六'];
    if (weekdays.length == 7) return '每天';
    if (weekdays.isEmpty) return '无';
    return weekdays.map((d) => dayNames[d]).join('、');
  }

  PowerScheduleTask copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    List<int>? weekdays,
    PowerScheduleType? type,
  }) {
    return PowerScheduleTask(
      id: id,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      type: type ?? this.type,
    );
  }
}

enum PowerScheduleType {
  powerOn,
  powerOff,
}
