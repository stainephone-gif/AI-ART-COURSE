import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class SmartAlarmService {
  static StreamSubscription<AccelerometerEvent>? _subscription;
  static final List<double> _movementBuffer = [];
  static const _bufferSize = 60; // 1 minute of samples at ~1/sec
  static Timer? _sampleTimer;
  static AccelerometerEvent? _lastEvent;

  static bool _isMonitoring = false;
  static bool get isMonitoring => _isMonitoring;

  static void startMonitoring(VoidCallback onMovementDetected) {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _movementBuffer.clear();

    _subscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      _lastEvent = event;
    });

    // Sample movement magnitude every second
    _sampleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_lastEvent != null) {
        final mag = sqrt(_lastEvent!.x * _lastEvent!.x +
            _lastEvent!.y * _lastEvent!.y +
            _lastEvent!.z * _lastEvent!.z);
        // Subtract gravity (~9.8 m/s²)
        final movement = (mag - 9.81).abs();
        _movementBuffer.add(movement);
        if (_movementBuffer.length > _bufferSize) {
          _movementBuffer.removeAt(0);
        }
      }
    });
  }

  static void stopMonitoring() {
    _isMonitoring = false;
    _subscription?.cancel();
    _sampleTimer?.cancel();
    _subscription = null;
    _sampleTimer = null;
    _movementBuffer.clear();
  }

  static double get movementScore {
    if (_movementBuffer.isEmpty) return 0.0;
    final avg =
        _movementBuffer.reduce((a, b) => a + b) / _movementBuffer.length;
    return avg;
  }

  static bool isInLightSleep() {
    // Light sleep: minimal movement (< 0.3 m/s² average deviation from gravity)
    // Movement > 0.5 likely means awake or light sleep phase
    return movementScore < 0.5;
  }

  static SleepPhase get currentPhase {
    final score = movementScore;
    if (score < 0.15) return SleepPhase.deep;
    if (score < 0.5) return SleepPhase.light;
    return SleepPhase.awake;
  }
}

enum SleepPhase { awake, light, deep }

extension SleepPhaseExt on SleepPhase {
  String get label {
    switch (this) {
      case SleepPhase.awake:
        return 'Бодрствование';
      case SleepPhase.light:
        return 'Лёгкий сон';
      case SleepPhase.deep:
        return 'Глубокий сон';
    }
  }
}

typedef VoidCallback = void Function();
