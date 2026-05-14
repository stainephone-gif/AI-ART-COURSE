import 'package:audioplayers/audioplayers.dart';

enum SleepSound {
  whiteNoise,
  rain,
  forest,
  ocean,
  fan,
  fire,
}

extension SleepSoundExt on SleepSound {
  String get displayName {
    switch (this) {
      case SleepSound.whiteNoise:
        return 'Белый шум';
      case SleepSound.rain:
        return 'Дождь';
      case SleepSound.forest:
        return 'Лес';
      case SleepSound.ocean:
        return 'Океан';
      case SleepSound.fan:
        return 'Вентилятор';
      case SleepSound.fire:
        return 'Костёр';
    }
  }

  String get emoji {
    switch (this) {
      case SleepSound.whiteNoise:
        return '〰️';
      case SleepSound.rain:
        return '🌧️';
      case SleepSound.forest:
        return '🌲';
      case SleepSound.ocean:
        return '🌊';
      case SleepSound.fan:
        return '💨';
      case SleepSound.fire:
        return '🔥';
    }
  }

  // Free-to-use loopable audio URLs (myNoise / freesound compatible)
  String get audioUrl {
    switch (this) {
      case SleepSound.whiteNoise:
        return 'https://www.soundjay.com/misc/sounds/white-noise-1.mp3';
      case SleepSound.rain:
        return 'https://www.soundjay.com/nature/sounds/rain-01.mp3';
      case SleepSound.forest:
        return 'https://www.soundjay.com/nature/sounds/forest-ambience-1.mp3';
      case SleepSound.ocean:
        return 'https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3';
      case SleepSound.fan:
        return 'https://www.soundjay.com/misc/sounds/fan-1.mp3';
      case SleepSound.fire:
        return 'https://www.soundjay.com/nature/sounds/fire-1.mp3';
    }
  }
}

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static SleepSound? _currentSound;
  static bool _isPlaying = false;

  static bool get isPlaying => _isPlaying;
  static SleepSound? get currentSound => _currentSound;

  static Future<void> play(SleepSound sound) async {
    await stop();
    _currentSound = sound;
    _isPlaying = true;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.7);

    try {
      await _player.play(UrlSource(sound.audioUrl));
    } catch (_) {
      _isPlaying = false;
    }
  }

  static Future<void> stop() async {
    _isPlaying = false;
    _currentSound = null;
    await _player.stop();
  }

  static Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  static void dispose() {
    _player.dispose();
  }

  static Stream<PlayerState> get stateStream => _player.onPlayerStateChanged;
}
