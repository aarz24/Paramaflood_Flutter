import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SirenService {
  static final SirenService _instance = SirenService._internal();
  factory SirenService() => _instance;
  SirenService._internal();

  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static bool _isMuted = false;

  static bool get isPlaying => _isPlaying;
  static bool get isMuted => _isMuted;

  static final ValueNotifier<bool> isSirenActiveNotifier = ValueNotifier<bool>(false);

  /// Initialize AudioPlayer configuration
  static Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      _player.onPlayerStateChanged.listen((state) {
        _isPlaying = (state == PlayerState.playing);
        isSirenActiveNotifier.value = _isPlaying;
      });
      debugPrint('SirenService initialized with air raid siren audio');
    } catch (e) {
      debugPrint('SirenService init error: $e');
    }
  }

  /// Start playing the air raid siren in loop
  static Future<void> startAirRaidSiren() async {
    if (_isMuted || _isPlaying) return;

    try {
      await _player.stop();
      await _player.setVolume(1.0);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/flood_air_raid_siren.mp3'));
      _isPlaying = true;
      isSirenActiveNotifier.value = true;
      debugPrint('🚨 AIR RAID SIREN STARTED (Water reached sensor tip <= 20cm)');
    } catch (e) {
      debugPrint('SirenService play error: $e');
    }
  }

  /// Stop the air raid siren
  static Future<void> stopAirRaidSiren() async {
    try {
      await _player.stop();
      _isPlaying = false;
      isSirenActiveNotifier.value = false;
      debugPrint('Air raid siren stopped');
    } catch (e) {
      debugPrint('SirenService stop error: $e');
    }
  }

  /// Manually mute siren for current emergency session
  static Future<void> muteSiren() async {
    _isMuted = true;
    await stopAirRaidSiren();
  }

  /// Reset mute state
  static void unmute() {
    _isMuted = false;
  }
}
