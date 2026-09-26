import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class AudioService {
  static bool _soundEnabled = true;
  static bool _hapticsEnabled = true;

  static Future<void> init() async {
    try {
      _soundEnabled = await StorageService.getSoundEnabled();
      _hapticsEnabled = await StorageService.getHapticsEnabled();

      await FlameAudio.audioCache.loadAll([
        'hit_drive.mp3',
        'hit_smash.mp3',
        'hit_speedup.mp3',
        'fault.mp3',
        'beep.mp3',
      ]);
    } catch (e) {
      debugPrint('Audio preloading warning: $e');
    }
  }

  static void updateSettings(bool sound, bool haptics) {
    _soundEnabled = sound;
    _hapticsEnabled = haptics;
  }

  // Alias for groupmate's engine methods
  static void playShotSfx(String type) => playHitSound(type);
  static void playFaultSfx() => playHitSound('FAULT');

  static void playHitSound(String type) {
    if (!_soundEnabled) return;
    try {
      switch (type.toUpperCase()) {
        case 'SMASH':
        case 'ULTIMATE':
          FlameAudio.play('hit_smash.mp3');
          if (_hapticsEnabled) HapticFeedback.mediumImpact();
          break;
        case 'FAULT':
          FlameAudio.play('fault.mp3');
          if (_hapticsEnabled) HapticFeedback.heavyImpact();
          break;
        case 'ROLL':
        case 'SLICE':
        case 'SPEEDUP':
          FlameAudio.play('hit_speedup.mp3');
          if (_hapticsEnabled) HapticFeedback.lightImpact();
          break;
        case 'DRIVE':
        case 'SERVE':
        case 'LOB':
        default:
          FlameAudio.play('hit_drive.mp3');
          if (_hapticsEnabled) HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      debugPrint('Error playing sound $type: $e');
    }
  }
}
