import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling FCM background message: ${message.messageId}');
  // Background notifications with 'notification' payload are shown automatically by Android OS.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'flood_emergency_channel';
  static const String channelName = 'Peringatan Darurat Banjir ParamaFlood';
  static const String channelDescription =
      'Notifikasi darurat dan peringatan dini kenaikan ketinggian air kanal kampus Universitas Paramadina.';
  static const String campusTopic = 'paramadina_flood_alerts';

  static bool _isInitialized = false;
  static String? _fcmToken;
  static DateTime? _lastAlertNotificationTime;
  static String? _lastAlertLevel;

  static String? get fcmToken => _fcmToken;
  static bool get isInitialized => _isInitialized;

  /// Initialize Firebase Cloud Messaging & Local Notifications
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Request Notification Permissions (iOS & Android 13+)
      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 2. Setup Android Notification Channel
      const String sirenChannelId = 'flood_air_raid_channel';
      const String sirenChannelName = 'Air Raid Flood Siren Alert';

      final AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
        sirenChannelId,
        sirenChannelName,
        description: 'Sirine Darurat Banjir Saat Air Mencapai Puncak Sensor (Blind Spot 20cm)',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('flood_air_raid_siren'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 2000]),
        ledColor: const Color(0xFFDC2626),
        enableLights: true,
      );

      final androidPlugin = _localNotif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(emergencyChannel);
        // Request Android 13+ permission specifically
        await androidPlugin.requestNotificationsPermission();
      }

      // 3. Initialize Flutter Local Notifications
      const AndroidInitializationSettings initAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: initAndroid,
        iOS: initIOS,
      );

      await _localNotif.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // 4. Subscribe to Universitas Paramadina campus flood alerts topic
      try {
        await _fcm.subscribeToTopic(campusTopic);
        debugPrint('Subscribed to FCM topic: $campusTopic');
      } catch (e) {
        debugPrint('Topic subscription skipped (e.g. simulator/web): $e');
      }

      // 5. Retrieve device FCM token
      try {
        _fcmToken = await _fcm.getToken();
        debugPrint('Device FCM Token: $_fcmToken');
      } catch (e) {
        debugPrint('Could not retrieve FCM token: $e');
      }

      // 6. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        final notif = message.notification;
        if (notif != null) {
          showNotification(
            title: notif.title ?? 'Peringatan ParamaFlood',
            body: notif.body ?? 'Status sensor kanal air diperbarui.',
            payload: message.data.toString(),
          );
        }
      });

      // 7. Handle notification click when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from notification: ${message.notification?.title}');
      });

      // 8. Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  /// Display an immediate emergency/high-priority push notification locally
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool isEmergency = false,
    bool playAirRaidSiren = false,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      playAirRaidSiren ? 'flood_air_raid_channel' : channelId,
      playAirRaidSiren ? 'Air Raid Flood Siren Alert' : channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ParamaFlood Air Raid Alert',
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFDC2626),
      playSound: true,
      sound: playAirRaidSiren
          ? const RawResourceAndroidNotificationSound('flood_air_raid_siren')
          : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      vibrationPattern: isEmergency || playAirRaidSiren
          ? Int64List.fromList([0, 1000, 400, 1000, 400, 2000])
          : Int64List.fromList([0, 300, 150, 300]),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'ParamaFlood Air Raid Alert',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotif.show(id, title, body, platformDetails, payload: payload);
  }

  /// Check water level or sensor danger and trigger emergency notification with cooldown
  static void checkSensorAlert({
    required double waterLevelCm,
    required double rainMm,
    required String riskLevel,
    double distanceCm = 100.0,
  }) {
    String? currentLevel;
    String title = '';
    String body = '';
    bool isEmergency = false;
    bool isAirRaid = false;
    final remainingCm = (100.0 - waterLevelCm).clamp(0.0, 100.0).toStringAsFixed(0);

    // Extreme condition: Water reached sensor tip (JSN-SR04T blind spot <= 20cm) or canal overflow
    if ((distanceCm > 0 && distanceCm <= 20.0) || waterLevelCm >= 100.0) {
      currentLevel = 'MELUAP';
      isEmergency = true;
      isAirRaid = true;
      title = '🚨🚨 AIR RAID SIREN: AIR MENCAPAI PUNCAK KANAL! ($remainingCm cm)';
      body = 'Air telah menyentuh batas ujung sensor (≤20 cm)! Tanggul kanal meluap! Evakuasi seluruh sivitas ke lantai atas sekarang juga!';
    } else if (waterLevelCm >= 85.0 || riskLevel == 'KRITIS') {
      currentLevel = 'KRITIS';
      isEmergency = true;
      title = '🚨 BAHAYA! Tinggal $remainingCm cm Lagi Banjir! (${waterLevelCm.toStringAsFixed(0)} cm)';
      body = 'Kanal mendekati bibir tanggul! Hanya tersisa $remainingCm cm sebelum air meluap. Segera evakuasi lantai dasar sekarang!';
    } else if (waterLevelCm >= 70.0 || riskLevel == 'TINGGI') {
      currentLevel = 'SIAGA';
      isEmergency = true;
      title = '⚠️ SIAGA BANJIR: Sisa $remainingCm cm Sebelum Meluap (${waterLevelCm.toStringAsFixed(0)} cm)';
      body = 'Kenaikan air kanal sangat cepat! Bersiap untuk evakuasi darurat.';
    } else if (rainMm >= 20.0) {
      currentLevel = 'HUJAN_LEBAT';
      title = '🌧️ Hujan Ekstrem Terdeteksi (${rainMm.toStringAsFixed(1)} mm/jam)';
      body = 'Curah hujan tinggi di sekitar kampus. Pantau monitor ParamaFlood.';
    }

    if (currentLevel == null) return;

    // Cooldown check: do not repeat identical notification within 5 minutes
    final now = DateTime.now();
    if (_lastAlertNotificationTime != null && _lastAlertLevel == currentLevel) {
      if (now.difference(_lastAlertNotificationTime!).inMinutes < 5) {
        return;
      }
    }

    _lastAlertNotificationTime = now;
    _lastAlertLevel = currentLevel;

    showNotification(
      title: title,
      body: body,
      isEmergency: isEmergency,
      playAirRaidSiren: isAirRaid,
    );
  }

  /// Helper to send a test simulation flood alert with air raid siren sound
  static Future<void> sendTestFloodAlert() async {
    await showNotification(
      title: '🚨🚨 AIR RAID SIREN: Air Mencapai Puncak Sensor! (12 cm lagi)',
      body: 'Kanal mendekati bibir tanggul! Hanya tersisa 12 cm sebelum air meluap. Segera amankan lab lantai dasar dan evakuasi ke lantai atas!',
      isEmergency: true,
      playAirRaidSiren: true,
    );
  }
}
