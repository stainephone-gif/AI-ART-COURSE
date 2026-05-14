import 'dart:convert';

class AlarmModel {
  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final bool isSmartAlarm;
  final int smartWindowMinutes;
  final bool gradualAlarm;
  final List<bool> repeatDays; // Mon=0 .. Sun=6

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.isEnabled = true,
    this.isSmartAlarm = false,
    this.smartWindowMinutes = 30,
    this.gradualAlarm = false,
    List<bool>? repeatDays,
  }) : repeatDays = repeatDays ?? List.filled(7, false);

  AlarmModel copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    bool? isSmartAlarm,
    int? smartWindowMinutes,
    bool? gradualAlarm,
    List<bool>? repeatDays,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      isSmartAlarm: isSmartAlarm ?? this.isSmartAlarm,
      smartWindowMinutes: smartWindowMinutes ?? this.smartWindowMinutes,
      gradualAlarm: gradualAlarm ?? this.gradualAlarm,
      repeatDays: repeatDays ?? List.from(this.repeatDays),
    );
  }

  DateTime nextAlarmTime() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      next = next.add(const Duration(days: 1));
    }
    if (repeatDays.any((d) => d)) {
      for (int i = 0; i < 7; i++) {
        final candidate = DateTime(now.year, now.month, now.day, hour, minute)
            .add(Duration(days: i));
        final weekday = candidate.weekday - 1; // 0=Mon
        if (repeatDays[weekday] && candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    return next;
  }

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': isEnabled,
        'isSmartAlarm': isSmartAlarm,
        'smartWindowMinutes': smartWindowMinutes,
        'gradualAlarm': gradualAlarm,
        'repeatDays': repeatDays,
      };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'] as int,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        label: json['label'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? true,
        isSmartAlarm: json['isSmartAlarm'] as bool? ?? false,
        smartWindowMinutes: json['smartWindowMinutes'] as int? ?? 30,
        gradualAlarm: json['gradualAlarm'] as bool? ?? false,
        repeatDays: (json['repeatDays'] as List<dynamic>?)
                ?.map((e) => e as bool)
                .toList() ??
            List.filled(7, false),
      );

  String toJsonString() => jsonEncode(toJson());
  factory AlarmModel.fromJsonString(String s) =>
      AlarmModel.fromJson(jsonDecode(s));
}
