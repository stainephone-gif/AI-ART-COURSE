import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../models/sleep_record.dart';

class StorageService {
  static const _alarmsKey = 'alarms';
  static const _sleepRecordsKey = 'sleep_records';
  static const _sleepStartKey = 'sleep_start';

  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_alarmsKey) ?? [];
    return list.map((s) => AlarmModel.fromJsonString(s)).toList();
  }

  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _alarmsKey, alarms.map((a) => a.toJsonString()).toList());
  }

  static Future<void> saveAlarm(AlarmModel alarm) async {
    final alarms = await loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      alarms[idx] = alarm;
    } else {
      alarms.add(alarm);
    }
    await saveAlarms(alarms);
  }

  static Future<void> deleteAlarm(int id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }

  static Future<List<SleepRecord>> loadSleepRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_sleepRecordsKey) ?? [];
    return list.map((s) => SleepRecord.fromJsonString(s)).toList();
  }

  static Future<void> saveSleepRecord(SleepRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_sleepRecordsKey) ?? [];
    list.add(record.toJsonString());
    await prefs.setStringList(_sleepRecordsKey, list);
  }

  static Future<void> saveSleepStart(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sleepStartKey, time.toIso8601String());
  }

  static Future<DateTime?> loadSleepStart() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_sleepStartKey);
    return s != null ? DateTime.tryParse(s) : null;
  }

  static Future<void> clearSleepStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sleepStartKey);
  }

  static int generateAlarmId() =>
      DateTime.now().millisecondsSinceEpoch % 100000;
}
