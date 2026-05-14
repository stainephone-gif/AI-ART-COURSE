import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

class SleepSoundsScreen extends StatefulWidget {
  const SleepSoundsScreen({super.key});

  @override
  State<SleepSoundsScreen> createState() => _SleepSoundsScreenState();
}

class _SleepSoundsScreenState extends State<SleepSoundsScreen> {
  SleepSound? _playing;
  double _volume = 0.7;
  int _timerMinutes = 0; // 0 = off
  Timer? _stopTimer;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  final List<int> _timerOptions = [0, 15, 30, 60, 90];

  @override
  void dispose() {
    _stopTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleSound(SleepSound sound) async {
    if (_playing == sound) {
      await SoundService.stop();
      _stopTimer?.cancel();
      _countdownTimer?.cancel();
      setState(() {
        _playing = null;
        _remainingSeconds = 0;
      });
    } else {
      await SoundService.play(sound);
      setState(() => _playing = sound);
      _startTimer();
      await StorageService.saveSleepStart(DateTime.now());
    }
  }

  void _startTimer() {
    _stopTimer?.cancel();
    _countdownTimer?.cancel();
    if (_timerMinutes > 0) {
      _remainingSeconds = _timerMinutes * 60;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _countdownTimer?.cancel();
          }
        });
      });
      _stopTimer = Timer(Duration(minutes: _timerMinutes), () async {
        await SoundService.stop();
        if (mounted) setState(() => _playing = null);
      });
    }
  }

  String get _timerLabel {
    if (_timerMinutes == 0) return 'Не выключать';
    if (_remainingSeconds > 0) {
      final m = _remainingSeconds ~/ 60;
      final s = _remainingSeconds % 60;
      return 'Выкл. через $m:${s.toString().padLeft(2, '0')}';
    }
    return '$_timerMinutes мин';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: const Text('Звуки для сна'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sound grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: SleepSound.values.length,
            itemBuilder: (_, i) {
              final sound = SleepSound.values[i];
              final isActive = _playing == sound;
              return GestureDetector(
                onTap: () => _toggleSound(sound),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2A3F6F)
                        : const Color(0xFF1A2744),
                    borderRadius: BorderRadius.circular(16),
                    border: isActive
                        ? Border.all(
                            color: const Color(0xFF7B8CDE), width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sound.emoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text(
                        sound.displayName,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF90A4AE),
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        const Icon(Icons.music_note,
                            size: 14, color: Color(0xFF7B8CDE)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Volume
          if (_playing != null) ...[
            Row(
              children: [
                const Icon(Icons.volume_down,
                    color: Color(0xFF546E7A), size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      SoundService.setVolume(v);
                    },
                    activeColor: const Color(0xFF7B8CDE),
                    inactiveColor: const Color(0xFF1A2744),
                  ),
                ),
                const Icon(Icons.volume_up,
                    color: Color(0xFF546E7A), size: 20),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Timer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2744),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Color(0xFF7B8CDE)),
                    const SizedBox(width: 8),
                    const Text('Таймер выключения',
                        style: TextStyle(
                            color: Colors.white, fontSize: 15)),
                    const Spacer(),
                    Text(
                      _timerLabel,
                      style: TextStyle(
                        color: _remainingSeconds > 0
                            ? const Color(0xFF7B8CDE)
                            : const Color(0xFF546E7A),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _timerOptions.map((min) {
                    final isSelected = _timerMinutes == min;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _timerMinutes = min);
                        if (_playing != null) _startTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7B8CDE)
                              : const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          min == 0 ? '∞' : '$min м',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF546E7A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
