import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/weather_data.dart';
import '../services/app_state.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../services/app_theme.dart';
import '../widgets/ai_chat_panel.dart';
import '../widgets/ai_insight_panel.dart';
import '../widgets/hero_panel.dart';
import '../widgets/sensor_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _trend(double? cur, double? prev, double threshold) {
    if (cur == null || prev == null) return '—';
    if (cur - prev > threshold) return '↑';
    if (cur - prev < -threshold) return '↓';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const AiChatPanel(),
          );
        },
        icon: const Icon(Icons.smart_toy_rounded),
        label: Text(
          'Tanya ParaBot',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        backgroundColor: AppTheme.heroAcc,
        foregroundColor: AppTheme.bg,
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.bg, AppTheme.bgAlt],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.colDist.withOpacity(0.22),
                      AppTheme.colDist.withOpacity(0.0),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.15, duration: 5.seconds),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -160,
            child: IgnorePointer(
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.colRain.withOpacity(0.18),
                      AppTheme.colRain.withOpacity(0.0),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.08, duration: 7.seconds),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.12,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),
          ),
          SafeArea(
            child: Selector<AppState, _DashData>(
              selector: (_, state) => _DashData(
                live: state.live,
                prev: state.prev,
                internet: state.internet,
                history: state.history,
                locationName: state.locationName,
                frameCount: state.frameCount,
                locationLoading: state.locationLoading,
                locationDeniedForever: state.locationDeniedForever,
                hasReceivedLiveData: state.hasReceivedLiveData,
                error: state.error,
              ),
              shouldRebuild: (previous, next) => previous != next,
              builder: (context, data, _) {
                final live = data.live;
                final previous = data.prev;
                final internet = data.internet;

                return RefreshIndicator(
                  color: AppTheme.heroAcc,
                  backgroundColor: AppTheme.cardSolid,
                  onRefresh: () => context.read<AppState>().refreshInternet(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _AppBar(
                          onRefresh: () => context.read<AppState>().refreshInternet(),
                          locationName: data.locationName,
                          online: live.isOnline,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _SectionIntro(
                          locationName: data.locationName,
                          online: live.isOnline,
                          internet: internet,
                          locationLoading: data.locationLoading,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: HeroPanel(
                            live: live,
                            internet: internet,
                            locationName: data.locationName,
                            isOnline: live.isOnline,
                            frameCount: data.frameCount,
                            locationLoading: data.locationLoading,
                            locationDeniedForever: data.locationDeniedForever,
                          ).animate().fadeIn(duration: 400.ms),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      // 🧠 Panel Analisis AI Gemini
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: const AiInsightPanel()
                              .animate()
                              .fadeIn(delay: 60.ms)
                              .slideY(begin: 0.1),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      // Show waiting banner when no real data yet
                      if (!data.hasReceivedLiveData)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.heroAcc.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.heroAcc.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.heroAcc,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.error.isNotEmpty
                                            ? 'Firebase Connection Issue'
                                            : 'Waiting for sensor data…',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.text,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data.error.isNotEmpty
                                            ? data.error
                                            : 'Connecting to ESP32 via Firebase Realtime Database',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.subtext,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!data.hasReceivedLiveData)
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          delegate: SliverChildListDelegate([
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'TEMP',
                                unit: '°C',
                                value: live.temp,
                                minVal: -10,
                                maxVal: 50,
                                color: AppTheme.colTemp,
                                label: live.tempLabel,
                                trend: _trend(live.temp, previous?.temp, 0.5),
                                compareValue: internet != null ? '${internet.temp.toStringAsFixed(1)}°C' : null,
                              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'HUM',
                                unit: '%',
                                value: live.hum,
                                minVal: 0,
                                maxVal: 100,
                                color: AppTheme.colHum,
                                label: live.humLabel,
                                trend: _trend(live.hum, previous?.hum, 1),
                                compareValue: internet != null ? '${internet.hum.toStringAsFixed(0)}%' : null,
                              ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'WIND',
                                unit: 'm/s',
                                value: live.wind,
                                minVal: 0,
                                maxVal: 20,
                                color: AppTheme.colWind,
                                label: live.windLabel,
                                trend: _trend(live.wind, previous?.wind, 0.1),
                                compareValue: internet != null ? '${internet.windSpeed.toStringAsFixed(1)}m/s' : null,
                              ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'LIGHT',
                                unit: ' lx',
                                value: live.light,
                                minVal: 0,
                                maxVal: 65000,
                                color: AppTheme.colLight,
                                label: live.lightLabel,
                                trend: _trend(live.light, previous?.light, 50.0),
                              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'RAIN',
                                unit: ' mm',
                                value: live.rain,
                                minVal: 0,
                                maxVal: 50,
                                color: AppTheme.colRain,
                                label: live.rainLabel,
                                trend: _trend(live.rain, previous?.rain, 0.1),
                              ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'WATER LVL',
                                unit: 'cm',
                                value: live.distance,
                                minVal: 0,
                                maxVal: 400,
                                color: AppTheme.colDist,
                                label: live.distanceLabel,
                                trend: _trend(live.distance, previous?.distance, 2.0),
                              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'BATTERY',
                                unit: 'V',
                                value: live.battery,
                                minVal: 8,
                                maxVal: 14,
                                color: AppTheme.colBatt,
                                label: live.batteryLabel,
                                trend: _trend(live.battery, previous?.battery, 0.2),
                                compareValue: '${((live.battery - 9.0) / (12.6 - 9.0) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.15),
                            ),
                          ]),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      if (kDebugMode) ...[
                        const SliverToBoxAdapter(
                          child: _SectionLabel(
                            title: 'TEST DATA',
                            subtitle: 'Simulate extreme conditions without hardware (Debug Only)',
                          ),
                        ),
                        const SliverToBoxAdapter(child: _TestPanel()),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashData {
  final WeatherData live;
  final WeatherData? prev;
  final InternetWeather? internet;
  final List<WeatherData> history;
  final String locationName;
  final int frameCount;
  final bool locationLoading;
  final bool locationDeniedForever;
  final bool hasReceivedLiveData;
  final String error;

  const _DashData({
    required this.live,
    required this.prev,
    required this.internet,
    required this.history,
    required this.locationName,
    required this.frameCount,
    required this.locationLoading,
    required this.locationDeniedForever,
    required this.hasReceivedLiveData,
    required this.error,
  });

  @override
  bool operator ==(Object other) {
    return other is _DashData &&
        live.timestamp == other.live.timestamp &&
        history.length == other.history.length &&
        internet?.fetchedAt == other.internet?.fetchedAt &&
        locationName == other.locationName &&
        locationLoading == other.locationLoading &&
        hasReceivedLiveData == other.hasReceivedLiveData &&
        error == other.error;
  }

  @override
  int get hashCode => Object.hash(
        live.timestamp,
        history.length,
        internet?.fetchedAt,
        locationName,
        locationLoading,
        hasReceivedLiveData,
        error,
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    const spacing = 54.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionIntro extends StatelessWidget {
  final String locationName;
  final bool online;
  final InternetWeather? internet;
  final bool locationLoading;

  const _SectionIntro({
    required this.locationName,
    required this.online,
    required this.internet,
    required this.locationLoading,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = locationLoading ? 'Locating device...' : locationName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              AppTheme.card.withOpacity(0.72),
              AppTheme.cardSolid.withOpacity(0.92),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather intelligence, polished for the browser',
              style: GoogleFonts.outfit(
                color: AppTheme.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Realtime sensor telemetry, location context, and internet comparison in one view.',
              style: GoogleFonts.outfit(
                color: AppTheme.subtext,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(Icons.place_outlined, statusText, AppTheme.heroAcc),
                _pill(Icons.bolt_outlined,
                    online ? 'Realtime connected' : 'Device offline',
                    online ? AppTheme.online : AppTheme.offline),
                _pill(Icons.cloud_outlined,
                    internet != null ? 'Internet weather ready' : 'Awaiting Open-Meteo',
                    AppTheme.internet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: AppTheme.subtext,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  final String locationName;
  final bool online;

  const _AppBar({
    required this.onRefresh,
    required this.locationName,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.card.withOpacity(0.95),
            AppTheme.cardSolid.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppTheme.heroAcc.withOpacity(0.25),
                  AppTheme.internet.withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.cloud_outlined, color: AppTheme.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARAMAFLOOD MONITOR',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ESP32 flood monitoring · $locationName',
                  style: GoogleFonts.outfit(
                    color: AppTheme.subtext,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (online ? AppTheme.online : AppTheme.offline).withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (online ? AppTheme.online : AppTheme.offline).withOpacity(0.35),
              ),
            ),
            child: Text(
              online ? 'LIVE' : 'OFFLINE',
              style: GoogleFonts.outfit(
                color: online ? AppTheme.online : AppTheme.offline,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.heroAcc, size: 22),
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _TestPanel extends StatefulWidget {
  const _TestPanel();

  @override
  State<_TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<_TestPanel> {
  bool _expanded = false;

  static WeatherData _wd(double t, double h, double p, double w, double l, double r, double d, double b) {
    return WeatherData(
      temp: t,
      hum: h,
      pres: p,
      wind: w,
      light: l,
      rain: r,
      distance: d,
      battery: b,
      timestamp: DateTime.now(),
    );
  }

  static final _presets = [
    ('HOT & HUMID', _wd(38.5, 85, 1008, 2.1, 45000, 0.0, 110.0, 12.4)),
    ('COLD & DRY', _wd(4.2, 22, 1025, 0.4, 25000, 0.0, 80.0, 11.2)),
    ('STORMY', _wd(16, 95, 978, 14.5, 150, 4.2, 40.0, 12.0)),
    ('MILD', _wd(22, 55, 1013, 3.2, 32000, 0.0, 120.0, 12.6)),
    ('ISMAILIA', _wd(28.5, 42, 1011, 4.3, 55000, 0.0, 95.0, 12.2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.heroAcc.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.science_outlined,
                    color: AppTheme.heroAcc,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SIMULATOR / TEST DATA',
                    style: GoogleFonts.outfit(
                      color: AppTheme.heroAcc,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) => _btn(context, preset.$1, preset.$2)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, WeatherData data) {
    return GestureDetector(
      onTap: () async {
        await context.read<AppState>().pushTestData(data);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pushed: $label',
                style: GoogleFonts.outfit(
                  color: AppTheme.bg,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppTheme.heroAcc,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.heroAcc.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.heroAcc.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.heroAcc,
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
