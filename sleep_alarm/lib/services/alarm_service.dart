import 'package:alarm/alarm.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> scheduleAlarm(AlarmModel model) async {
    if (!model.isEnabled) return;

    final alarmTime = model.nextAlarmTime();

    final settings = AlarmSettings(
      id: model.id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/marimba.mp3',
      loopAudio: true,
      vibrate: true,
      volume: model.gradualAlarm ? 0.1 : 1.0,
      fadeDuration: model.gradualAlarm ? 120.0 : 0.0,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: model.label.isEmpty ? 'Будильник' : model.label,
        body: model.timeString,
        stopButton: 'Выключить',
        icon: 'notification_icon',
      ),
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> stopRinging(int id) async {
    await Alarm.stop(id);
  }

  static Stream<AlarmSettings?> get ringStream => Alarm.ringStream.stream;
}
