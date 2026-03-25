String parseTimeStr(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  final hh = hours.toString().padLeft(2, '0');
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  if (days > 0) {
    return '$days天 $hh:$mm:$ss';
  }

  return '$hh:$mm:$ss';
}

String? parseOpTime(String? optime) {
  if (optime == null) return null;
  List items = optime.split(":");
  int days = int.parse(items[0]) ~/ 24;
  items[0] = (int.parse(items[0]) % 24).toString().padLeft(2, "0");
  items[1] = items[1].toString().padLeft(2, "0");
  items[2] = items[2].toString().padLeft(2, "0");
  return "${days > 0 ? "$days天" : ""} ${items.join(":")}";
}
