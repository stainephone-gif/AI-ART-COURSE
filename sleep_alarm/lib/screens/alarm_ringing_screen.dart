import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../models/sleep_record.dart';
import '../widgets/sleep_quality_dialog.dart';

class AlarmRingingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _snoozeTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _snoozeTimer?.cancel();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await AlarmService.stopRinging(widget.alarmSettings.id);
    if (!mounted) return;

    final sleepStart = await StorageService.loadSleepStart();
    await StorageService.clearSleepStart();

    if (sleepStart != null && mounted) {
      final quality = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SleepQualityDialog(),
      );
      if (quality != null) {
        await StorageService.saveSleepRecord(SleepRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sleepTime: sleepStart,
          wakeTime: DateTime.now(),
          quality: quality,
        ));
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    await AlarmService.stopRinging(widget.alarmSettings.id);
    _snoozeTimer = Timer(const Duration(minutes: 10), () {});
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final title = widget.alarmSettings.notificationSettings.title;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nightlight_round,
                  color: Color(0xFF7B8CDE), size: 64),
              const SizedBox(height: 32),
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 20,
                    fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 64),
              ScaleTransition(
                scale: _pulseAnimation,
                child: ElevatedButton(
                  onPressed: _dismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B8CDE),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 64),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                  ),
                  child: const Text('Выключить',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _snooze,
                child: const Text(
                  'Отложить на 10 мин',
                  style:
                      TextStyle(color: Color(0xFF90A4AE), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
