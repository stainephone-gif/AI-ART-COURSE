import 'package:alarm/alarm.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> scheduleAlarm(AlarmModel model) async {
    if (!model.isEnabled) return;

    final alarmTime = model.nextAlarmTime();

    final volumeSettings = model.gradualAlarm
        ? VolumeSettings.fade(
            volume: 1.0,
            fadeDuration: const Duration(seconds: 120),
          )
        : const VolumeSettings.fixed(volume: 1.0);

    final settings = AlarmSettings(
      id: model.id,
      dateTime: alarmTime,
      volumeSettings: volumeSettings,
      notificationSettings: NotificationSettings(
        title: model.label.isEmpty ? 'Будильник' : model.label,
        body: model.timeString,
        stopButton: 'Выключить',
        icon: 'notification_icon',
      ),
      // Built-in asset from the alarm package
      assetAudioPath: 'packages/alarm/assets/marimba.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> stopRinging(int id) async {
    await Alarm.stop(id);
  }

  // alarm 5.x: use Alarm.ringing stream (AlarmSet) and map to first ringing alarm
  static Stream<AlarmSettings?> get ringStream =>
      Alarm.ringing.map((set) => set.alarms.firstOrNull);
}
