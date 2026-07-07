import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import '../services/firebase_service.dart';
import '../services/location_weather_service.dart';

class AppState extends ChangeNotifier {
  final _firebase = FirebaseService();
  final _locSvc   = LocationWeatherService();

  WeatherData       _live    = WeatherData(
    temp: 24.5,
    hum: 52.0,
    pres: 1013.25,
    wind: 2.4,
    light: 850.0,
    rain: 0.0,
    distance: 120.0,
    battery: 12.2,
    timestamp: DateTime.now(),
  );
  WeatherData?      _prev;
  List<WeatherData> _history = [];
  InternetWeather?  _internet;
  int               _frameCount = 0;
  String            _error      = '';
  bool              _locationLoading = true;

  StreamSubscription<WeatherData>?       _liveSub;
  StreamSubscription<List<WeatherData>>? _histSub;
  Timer?                                 _internetTimer;

  AppState() {
    // Pre-populate mock history so charts are fully populated on load
    final nowTime = DateTime.now();
    for (int i = 47; i >= 0; i--) {
      final t = nowTime.subtract(Duration(minutes: 10 * i));
      _history.add(WeatherData(
        temp: 21.0 + (i % 6) * 0.8,
        hum: 45.0 + (i % 8) * 2.5,
        pres: 1010.0 + (i % 10) * 0.5,
        wind: 1.2 + (i % 5) * 0.4,
        light: 500.0 + (i % 12) * 200,
        rain: (i % 24 == 0) ? 0.70 : 0.0,
        distance: 150.0 - (i % 10) * 2.5,
        battery: 12.4 - (i / 48) * 0.5,
        timestamp: t,
      ));
    }
  }

  WeatherData       get live            => _live;
  WeatherData?      get prev            => _prev;
  List<WeatherData> get history         => _history;
  InternetWeather?  get internet        => _internet;
  int               get frameCount      => _frameCount;
  String            get locationName    => _locSvc.locationName;
  String            get error           => _error;
  bool              get locationLoading => _locationLoading;
  bool              get locationDeniedForever => _locSvc.permissionDeniedForever;

  Future<void> init() async {
    // ── Firebase live stream — updates every ~1 second ──────────
    _liveSub = _firebase.liveStream.listen(
      (d) {
        _prev = _live;
        _live = d;
        _frameCount++;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Firebase stream error (running in offline mode): $e');
        _error = 'Firebase offline';
        notifyListeners();
      },
    );

    // ── Firebase history stream ──────────────────────────────────
    _histSub = _firebase.historyStream.listen(
      (list) {
        if (list.isNotEmpty) {
          _history = list;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('Firebase history error (using offline mock data): $e');
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
    _frameCount++;
    _history.add(d);
    if (_history.length > 48) {
      _history.removeAt(0);
    }
    notifyListeners();

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
