class ScheduleTime {
  final String day;
  final String start;
  final String end;

  ScheduleTime({
    required this.day,
    required this.start,
    required this.end,
  });

  factory ScheduleTime.fromJson(Map<String, dynamic> json) {
    return ScheduleTime(
      day: json['day'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}
