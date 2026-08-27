import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weather_data.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/location_weather_service.dart';
import '../services/notification_service.dart';
import '../services/siren_service.dart';
import '../services/voice_alert_service.dart';

class AppState extends ChangeNotifier {
  final _auth     = AuthService();
  final _firebase = FirebaseService();
  final _locSvc   = LocationWeatherService();
  final _gemini   = GeminiService();

  WeatherData       _live    = WeatherData.empty();
  WeatherData?      _prev;
  List<WeatherData> _history = [];
  InternetWeather?  _internet;
  int               _frameCount = 0;
  String            _error      = '';
  bool              _locationLoading = true;
  bool              _hasReceivedLiveData = false;
  bool              _hasReceivedHistory  = false;

  // ── AI State ──────────────────────────────────────────────────
  String _aiAnalysis = '';
  String _floodRiskLevel = 'UNKNOWN'; // RENDAH, SEDANG, TINGGI, KRITIS, UNKNOWN
  bool   _isAiLoading = false;
  String _aiError = '';
  bool   _isChatLoading = false;
  String _dailyReport = '';
  bool   _isReportLoading = false;
  String _smartAlert = '';
  DateTime? _lastAlertTime;

  // Structured AI fields (compact card format)
  String _aiCuaca = '';  // 1-line weather summary
  String _aiAir   = '';  // 1-line water status
  String _aiSaran = '';  // 1-line recommendation
  String _aiDetail = ''; // 2-3 sentence detailed analysis
  final List<Map<String, String>> _chatMessages = [];

  StreamSubscription<WeatherData>?       _liveSub;
  StreamSubscription<List<WeatherData>>? _histSub;
  Timer?                                 _internetTimer;

  AppState();

  WeatherData       get live            => _live;
  WeatherData?      get prev            => _prev;
  List<WeatherData> get history         => _history;
  InternetWeather?  get internet        => _internet;
  int               get frameCount      => _frameCount;
  String            get locationName    => _locSvc.locationName;
  String            get error           => _error;
  bool              get locationLoading => _locationLoading;
  bool              get locationDeniedForever => _locSvc.permissionDeniedForever;
  bool              get hasReceivedLiveData => _hasReceivedLiveData;
  bool              get hasReceivedHistory  => _hasReceivedHistory;

  // ── Auth Getters ──────────────────────────────────────────────
  AuthService       get auth            => _auth;
  User?             get currentUser     => _auth.currentUser;
  bool              get isAuthenticated => _auth.isAuthenticated;
  String            get userDisplayName => _auth.currentUser?.displayName ?? 'Sivitas Paramadina';
  String            get userEmail       => _auth.currentUser?.email ?? '';
  String?           get userPhotoUrl    => _auth.currentUser?.photoURL;
  String            get userCampusRole  => AuthService.getCampusRole(_auth.currentUser?.email);

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ── AI Getters ────────────────────────────────────────────────
  String get aiAnalysis      => _aiAnalysis;
  String get floodRiskLevel  => _floodRiskLevel;
  bool   get isAiLoading     => _isAiLoading;
  String get aiError         => _aiError;
  bool   get isChatLoading   => _isChatLoading;
  String get dailyReport     => _dailyReport;
  bool   get isReportLoading => _isReportLoading;
  String get smartAlert      => _smartAlert;
  bool   get isAiConfigured  => _gemini.isConfigured;
  List<Map<String, String>> get chatMessages => List.unmodifiable(_chatMessages);

  // Structured AI getters
  String get aiCuaca  => _aiCuaca;
  String get aiAir    => _aiAir;
  String get aiSaran  => _aiSaran;
  String get aiDetail => _aiDetail;
  bool   get hasStructuredAi => _aiCuaca.isNotEmpty || _aiAir.isNotEmpty;

  Future<void> init() async {
    // ── Firebase live stream — updates every ~1 second ──────────
    _liveSub = _firebase.liveStream.listen(
      (d) {
        _prev = _live;
        _live = d;
        final isFirstData = !_hasReceivedLiveData;
        _hasReceivedLiveData = true;
        _frameCount++;
        _error = '';
        notifyListeners();
        // Jalankan analisis AI pertama saat data live pertama diterima
        if (isFirstData) refreshAiAnalysis();
        _checkSmartAlerts(d);
      },
      onError: (e) {
        debugPrint('Firebase stream error (running in offline mode): $e');
        _error = 'Firebase offline – check google-services.json';
        notifyListeners();
      },
    );

    // ── Firebase history stream ──────────────────────────────────
    _histSub = _firebase.historyStream.listen(
      (list) {
        if (list.isNotEmpty) {
          _history = list;
          _hasReceivedHistory = true;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('Firebase history error: $e');
      },
    );

    // ── Location (runs in parallel, won't block Firebase) ────────
    _locationLoading = true;
    notifyListeners();

    _locSvc.init().then((_) async {
      _locationLoading = false;
      notifyListeners();
      await _refreshInternet();
    });

    // Auto-refresh internet weather every 10 minutes
    _internetTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _refreshInternet(),
    );

    // CATATAN KUOTA: free tier gemini-2.5-flash hanya ±20 request/HARI.
    // Auto-refresh 15 menit (~96/hari) akan menghabiskan kuota — jadi
    // analisis AI hanya berjalan saat data pertama masuk + refresh manual.
    // (Timer auto-refresh sengaja dinonaktifkan.)
  }

  // ── AI Methods ────────────────────────────────────────────────
  Future<void> refreshAiAnalysis() async {
    if (_isAiLoading) return;
    _isAiLoading = true;
    _aiError = '';
    notifyListeners();

    try {
      final res = await _gemini.analyzeWeather(
        current: _live,
        history: _history,
        internet: _internet,
      );
      final risk = res['risk'] ?? 'UNKNOWN';
      if (risk == 'COOLDOWN') {
        // Masih cooldown — tampilkan pesan tunggu tanpa menimpa hasil lama
        _aiError = res['analysis'] ?? '';
      } else {
        _floodRiskLevel = risk;
        _aiAnalysis = res['analysis'] ?? 'Tidak ada analisis.';
        _aiCuaca = res['cuaca'] ?? '';
        _aiAir = res['air'] ?? '';
        _aiSaran = res['saran'] ?? '';
        _aiDetail = res['detail'] ?? '';
      }
    } catch (e) {
      _aiError = 'Gagal memproses AI: $e';
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty || _isChatLoading) return;

    _chatMessages.add({'sender': 'user', 'message': text.trim()});
    _isChatLoading = true;
    notifyListeners();

    final reply = await _gemini.chat(
      userMessage: text.trim(),
      current: _live,
      history: _history,
      internet: _internet,
    );

    _chatMessages.add({'sender': 'bot', 'message': reply});
    _isChatLoading = false;
    notifyListeners();
  }

  Future<void> generateDailyReport() async {
    if (_isReportLoading) return;
    _isReportLoading = true;
    notifyListeners();

    _dailyReport = await _gemini.generateDailyReport(todayHistory: _history);
    _isReportLoading = false;
    notifyListeners();
  }

  void clearSmartAlert() {
    _smartAlert = '';
    notifyListeners();
  }

  /// Deteksi kondisi bahaya → minta AI buat notifikasi kontekstual.
  /// Maksimal satu alert per 30 menit — kuota free tier cuma ±20 req/hari.
  Future<void> _checkSmartAlerts(WeatherData d) async {
    if (_lastAlertTime != null &&
        DateTime.now().difference(_lastAlertTime!) <
            const Duration(minutes: 30)) {
      return;
    }

    String? alertType;
    if (d.distance > 0 && d.distance < 20) {
      alertType = 'flood';
    } else if (d.feelsLike > 40) {
      alertType = 'heat';
    } else if (d.battery > 0 && d.battery < 10.5) {
      alertType = 'battery';
    } else if (d.pres > 0 && d.pres < 990) {
      alertType = 'storm';
    }
    if (alertType == null) return;

    // 🚨 Air Raid Siren trigger: water reached sensor tip (distance <= 20cm)
    if (d.distance > 0 && d.distance <= 20.0) {
      SirenService.startAirRaidSiren();
      VoiceAlertService.speakFloodAlert(
        waterLevelCm: d.waterLevel,
        riskLevel: 'KRITIS',
      );
    } else if (d.distance > 25.0 && SirenService.isPlaying) {
      SirenService.stopAirRaidSiren();
    }

    // Trigger push notification if water level or rain is hazardous
    NotificationService.checkSensorAlert(
      waterLevelCm: d.waterLevel,
      rainMm: d.rain,
      riskLevel: _floodRiskLevel,
      distanceCm: d.distance,
    );
  }

  Future<void> _refreshInternet() async {
    final w = await _locSvc.fetchInternetWeather();
    if (w != null) {
      _internet = w;
      notifyListeners();
    }
  }

  Future<void> pushTestData(WeatherData d) async {
    // Update local state immediately for instant feedback
    _prev = _live;
    _live = d;
    _hasReceivedLiveData = true;
    _hasReceivedHistory = true;
    _frameCount++;
    _history.add(d);
    if (_history.length > 48) {
      _history.removeAt(0);
    }
    notifyListeners();
    _checkSmartAlerts(d);

    // Try to update Firebase in the background
    try {
      await _firebase.pushData(d).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Firebase push skipped or timed out (offline mode): $e');
    }
  }

  Future<void> refreshInternet() => _refreshInternet();

  /// Re-attempt location after user grants permission in settings
  Future<void> retryLocation() async {
    _locationLoading = true;
    notifyListeners();
    await _locSvc.init();
    _locationLoading = false;
    notifyListeners();
    await _refreshInternet();
  }

  Future<void> openLocationSettings() => _locSvc.openLocationSettings();
  Future<void> openAppSettings()      => _locSvc.openSettings();

  @override
  void dispose() {
    _liveSub?.cancel();
    _histSub?.cancel();
    _internetTimer?.cancel();
    super.dispose();
  }
}
