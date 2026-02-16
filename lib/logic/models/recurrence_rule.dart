import 'package:eat_beat_repeat/logic/utils/enums.dart';

class RecurrenceRule {
  final RecurrencePattern pattern;
  final List<int>?
  daysOfWeek; // 1=Mo, 2=Di, ..., 7=So (nur bei specificDaysOfWeek)

  RecurrenceRule._({
    required this.pattern,
    this.daysOfWeek,
  });

  factory RecurrenceRule.daily() {
    return RecurrenceRule._(pattern: RecurrencePattern.daily);
  }

  factory RecurrenceRule.weekdays() {
    return RecurrenceRule._(pattern: RecurrencePattern.weekdays);
  }

  factory RecurrenceRule.weekends() {
    return RecurrenceRule._(pattern: RecurrencePattern.weekends);
  }

  factory RecurrenceRule.specificDaysOfWeek(List<int> days) {
    return RecurrenceRule._(
      pattern: RecurrencePattern.specificDaysOfWeek,
      daysOfWeek: days,
    );
  }

  bool appliesToDate(DateTime date) {
    switch (pattern) {
      case RecurrencePattern.daily:
        return true;
      case RecurrencePattern.weekdays:
        return date.weekday >= 1 && date.weekday <= 5;
      case RecurrencePattern.weekends:
        return date.weekday == 6 || date.weekday == 7;
      case RecurrencePattern.specificDaysOfWeek:
        return daysOfWeek?.contains(date.weekday) ?? false;
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern.toString().split('.').last,
      'daysOfWeek': daysOfWeek,
    };
  }

  // JSON deserialization
  static RecurrenceRule fromJson(Map<String, dynamic> json) {
    return RecurrenceRule._(
      pattern: RecurrencePattern.values.firstWhere(
        (e) => e.toString().split('.').last == json['pattern'],
      ),
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : null,
    );
  }

  @override
  String toString() {
    return 'RecurrenceRule(pattern: $pattern, daysOfWeek: $daysOfWeek)';
  }
}
