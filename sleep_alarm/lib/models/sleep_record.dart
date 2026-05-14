import 'dart:convert';

class SleepRecord {
  final String id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final int quality; // 1-5
  final String notes;

  SleepRecord({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    required this.quality,
    this.notes = '',
  });

  Duration get duration => wakeTime.difference(sleepTime);

  double get durationHours => duration.inMinutes / 60.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sleepTime': sleepTime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'quality': quality,
        'notes': notes,
      };

  factory SleepRecord.fromJson(Map<String, dynamic> json) => SleepRecord(
        id: json['id'] as String,
        sleepTime: DateTime.parse(json['sleepTime'] as String),
        wakeTime: DateTime.parse(json['wakeTime'] as String),
        quality: json['quality'] as int,
        notes: json['notes'] as String? ?? '',
      );

  String toJsonString() => jsonEncode(toJson());
  factory SleepRecord.fromJsonString(String s) =>
      SleepRecord.fromJson(jsonDecode(s));
}
