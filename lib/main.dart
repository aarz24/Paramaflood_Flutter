import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/app_theme.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'services/siren_service.dart';
import 'services/voice_alert_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized by native Android layer — safe to continue
    debugPrint('Firebase init skipped: $e');
  }

  // Initialize Push Notifications (FCM & Local Emergency Alerts)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  // Initialize Voice Alert Broadcast Engine (Indonesian TTS)
  try {
    await VoiceAlertService.init();
  } catch (e) {
    debugPrint('VoiceAlert init error: $e');
  }

  // Initialize Air Raid Siren Audio Service
  try {
    await SirenService.init();
  } catch (e) {
    debugPrint('SirenService init error: $e');
  }

  runApp(const WxStationApp());
}

class WxStationApp extends StatelessWidget {
  const WxStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'ParamaFlood Monitor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
