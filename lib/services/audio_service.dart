import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class AudioService {
  static bool _soundEnabled = true;
  static bool _hapticsEnabled = true;

  // Initialize and preload audio files
  static Future<void> init() async {
    try {
      _soundEnabled = await StorageService.getSoundEnabled();
      _hapticsEnabled = await StorageService.getHapticsEnabled();

      // Preload .mp3 audio clips into memory
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

  // Play Impact SFX based on shot type
  static void playShotSfx(String shotType) {
    if (!_soundEnabled) return;

    try {
      switch (shotType) {
        case 'SMASH':
          FlameAudio.play('hit_smash.mp3', volume: 1.0);
          triggerHaptic(HapticType.heavy);
          break;
        case 'SPEED_UP':
          FlameAudio.play('hit_speedup.mp3', volume: 0.85);
          triggerHaptic(HapticType.medium);
          break;
        case 'ROLL':
        case 'DRIVE':
        default:
          FlameAudio.play('hit_drive.mp3', volume: 0.75);
          triggerHaptic(HapticType.light);
          break;
      }
    } catch (e) {
      debugPrint('Audio playback skipped: $e');
    }
  }

  // Play Fault / Out-of-bounds SFX
  static void playFaultSfx() {
    if (_soundEnabled) {
      try {
        FlameAudio.play('fault.mp3', volume: 0.8);
      } catch (e) {
        debugPrint('Audio playback skipped: $e');
      }
    }
    triggerHaptic(HapticType.heavy);
  }

  // Play Countdown Beep
  static void playBeepSfx() {
    if (_soundEnabled) {
      try {
        FlameAudio.play('beep.mp3', volume: 0.6);
      } catch (e) {
        debugPrint('Audio playback skipped: $e');
      }
    }
  }

  // Trigger Phone Vibration
  static void triggerHaptic(HapticType type) {
    if (!_hapticsEnabled || kIsWeb) return;

    try {
      switch (type) {
        case HapticType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          HapticFeedback.vibrate();
          break;
      }
    } catch (_) {}
  }
}

enum HapticType { light, medium, heavy }
