import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceAlertService {
  static final VoiceAlertService _instance = VoiceAlertService._internal();
  factory VoiceAlertService() => _instance;
  VoiceAlertService._internal();

  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isEnabled = true;
  static bool _isSpeaking = false;
  static DateTime? _lastVoiceAlertTime;
  static String? _lastSpokenLevel;

  static bool get isEnabled => _isEnabled;
  static bool get isSpeaking => _isSpeaking;

  /// Initialize TTS engine with Indonesian voice parameters
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('voice_alerts_enabled') ?? true;

      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.5); // Natural speaking speed
      await _tts.setVolume(1.0);     // Maximum clear volume
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('VoiceAlertService initialized (Language: id-ID, Enabled: $_isEnabled)');
    } catch (e) {
      debugPrint('VoiceAlertService init error: $e');
    }
  }

  /// Toggle voice alert preference
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_alerts_enabled', enabled);
    if (!enabled) {
      await stop();
    }
  }

  /// Speak emergency flood warning in Indonesian
  static Future<void> speakFloodAlert({
    required double waterLevelCm,
    required String riskLevel,
    bool force = false,
  }) async {
    if (!_isEnabled) return;

    // Cooldown check unless forced
    final now = DateTime.now();
    if (!force && _lastVoiceAlertTime != null && _lastSpokenLevel == riskLevel) {
      if (now.difference(_lastVoiceAlertTime!).inMinutes < 5) {
        return;
      }
    }

    final remainingCm = (100.0 - waterLevelCm).clamp(0.0, 100.0).toStringAsFixed(0);

    String message = '';
    if (waterLevelCm >= 100.0) {
      message = 'PERINGATAN KRITIS! KANAL AIR KAMPUS TELAH MELUAP! '
          'Ketinggian air telah melewati batas tanggul 100 sentimeter. '
          'Banjir sedang terjadi di area kampus. Segera jauhi saluran air dan evakuasi ke lantai atas sekarang juga!';
    } else if (waterLevelCm >= 85.0 || riskLevel == 'KRITIS') {
      message = 'BAHAYA! BAHAYA! Peringatan darurat banjir kampus! '
          'Ketinggian air kanal telah mencapai ${waterLevelCm.toStringAsFixed(0)} sentimeter. '
          'Hanya tersisa $remainingCm sentimeter lagi sebelum air meluap ke area kampus! '
          'Status darurat bencana. Segera evakuasi lantai dasar, putuskan aliran listrik, dan amankan aset laboratorium sekarang juga!';
    } else if (waterLevelCm >= 70.0 || riskLevel == 'TINGGI') {
      message = 'SIAGA SATU BANJIR! Laju kenaikan air kanal sangat cepat! '
          'Ketinggian air saat ini ${waterLevelCm.toStringAsFixed(0)} sentimeter. '
          'Tersisa $remainingCm sentimeter sebelum tanggul meluap. '
          'Potensi banjir besar dalam waktu dekat. Seluruh sivitas kampus harap bersiap evakuasi!';
    } else if (waterLevelCm >= 50.0 || riskLevel == 'SEDANG') {
      message = 'Perhatian. Ketinggian air kanal ${waterLevelCm.toStringAsFixed(0)} sentimeter, '
          'tersisa $remainingCm sentimeter sebelum ambang batas bahaya. '
          'Tetap waspada dan pantau monitor ParamaFlood.';
    } else if (force) {
      message = 'Status kanal normal. Ketinggian air ${waterLevelCm.toStringAsFixed(1)} sentimeter. '
          'Tersisa $remainingCm sentimeter ruang kapasitas aman. Sistem ParamaFlood aktif memonitor.';
    }

    if (message.isNotEmpty) {
      _lastVoiceAlertTime = now;
      _lastSpokenLevel = riskLevel;
      await speak(message);
    }
  }

  /// Speak raw text directly
  static Future<void> speak(String text) async {
    if (!_isEnabled) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Test simulation voice broadcast
  static Future<void> testVoiceAlert() async {
    await speak(
      'BAHAYA! BAHAYA! Peringatan darurat banjir ParamaFlood! '
      'Ketinggian air kanal terdeteksi 88 sentimeter. '
      'Hanya tersisa 12 sentimeter lagi sebelum air meluap ke area kampus! '
      'Segera evakuasi ke lantai atas sekarang juga!',
    );
  }

  /// Stop any ongoing speech immediately
  static Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
