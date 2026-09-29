
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/weather_data.dart';
import '../services/app_state.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../services/app_theme.dart';
import '../widgets/ai_insight_panel.dart';
import '../widgets/ai_chat_panel.dart';
import '../widgets/hero_panel.dart';
import '../widgets/sensor_card.dart';
import '../widgets/water_canal_visualizer.dart';

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
                      AppTheme.heroAcc.withValues(alpha: 0.08),
                      AppTheme.heroAcc.withValues(alpha: 0.0),
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
                      AppTheme.colHum.withValues(alpha: 0.06),
                      AppTheme.colHum.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.08, duration: 7.seconds),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.06,
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
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      
                      const SliverToBoxAdapter(
                        child: _SectionLabel(
                          title: 'Analisis AI',
                          subtitle: 'Ringkasan cerdas kondisi cuaca & banjir oleh Gemini',
                          icon: Icons.psychology_rounded,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: const AiInsightPanel()
                              .animate()
                              .fadeIn(delay: 60.ms)
                              .slideY(begin: 0.1),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 18)),

                      const SliverToBoxAdapter(
                        child: _SectionLabel(
                          title: 'Penampang Kanal',
                          subtitle: 'Visualisasi ketinggian air, hujan, dan angin secara langsung',
                          icon: Icons.water_rounded,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: RepaintBoundary(
                          child: Consumer<AppState>(
                            builder: (context, state, _) {
                              return WaterCanalVisualizer(
                                waterLevelCm: state.live.waterLevel,
                                rainRateMm: state.live.rain,
                                windSpeedMs: state.live.wind,
                                floodRiskLevel: state.floodRiskLevel,
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 90.ms).slideY(begin: 0.08),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      
                      // Show waiting banner when no real data yet
                      if (!data.hasReceivedLiveData)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.cardSolid,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (data.error.isNotEmpty
                                        ? AppTheme.offline
                                        : AppTheme.heroAcc)
                                    .withValues(alpha: 0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (data.error.isNotEmpty
                                          ? AppTheme.offline
                                          : AppTheme.heroAcc)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (data.error.isNotEmpty
                                            ? AppTheme.offline
                                            : AppTheme.heroAcc)
                                        .withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    data.error.isNotEmpty
                                        ? Icons.wifi_off_rounded
                                        : Icons.sensors_rounded,
                                    size: 22,
                                    color: data.error.isNotEmpty
                                        ? AppTheme.offline
                                        : AppTheme.heroAcc,
                                  ),
                                )
                                    .animate(
                                        onPlay: (c) =>
                                            c.repeat(reverse: true))
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.1, 1.1),
                                      duration: 1200.ms,
                                      curve: Curves.easeInOut,
                                    ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.error.isNotEmpty
                                            ? 'Kendala Koneksi Firebase'
                                            : 'Menunggu Data Sensor...',
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
                                            : 'Menghubungkan ke ESP32 via Firebase Realtime Database',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.subtext,
                                          fontSize: 11,
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

                      // Section Header: Telemetri Sensor
                      const SliverToBoxAdapter(
                        child: _SectionLabel(
                          title: 'Telemetri Sensor',
                          subtitle: 'Data pengukuran langsung stasiun cuaca & banjir ESP32',
                          icon: Icons.sensors_rounded,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildListDelegate([
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'SUHU',
                                unit: '°C',
                                value: live.temp,
                                minVal: -10,
                                maxVal: 50,
                                color: AppTheme.colTemp,
                                icon: Icons.thermostat_rounded,
                                label: live.tempLabel,
                                trend: _trend(live.temp, previous?.temp, 0.5),
                                compareValue: internet != null ? '${internet.temp.toStringAsFixed(1)}°C' : null,
                              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'KELEMBABAN',
                                unit: '%',
                                value: live.hum,
                                minVal: 0,
                                maxVal: 100,
                                color: AppTheme.colHum,
                                icon: Icons.water_drop_rounded,
                                label: live.humLabel,
                                trend: _trend(live.hum, previous?.hum, 1),
                                compareValue: internet != null ? '${internet.hum.toStringAsFixed(0)}%' : null,
                              ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'ANGIN',
                                unit: 'm/s',
                                value: live.wind,
                                minVal: 0,
                                maxVal: 20,
                                color: AppTheme.colWind,
                                icon: Icons.air_rounded,
                                label: live.windLabel,
                                trend: _trend(live.wind, previous?.wind, 0.1),
                                compareValue: internet != null ? '${internet.windSpeed.toStringAsFixed(1)}m/s' : null,
                              ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'CAHAYA',
                                unit: ' lx',
                                value: live.light,
                                minVal: 0,
                                maxVal: 65000,
                                color: AppTheme.colLight,
                                icon: Icons.wb_sunny_rounded,
                                label: live.lightLabel,
                                trend: _trend(live.light, previous?.light, 50.0),
                              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'HUJAN',
                                unit: ' mm',
                                value: live.rain,
                                minVal: 0,
                                maxVal: 50,
                                color: AppTheme.colRain,
                                icon: Icons.grain_rounded,
                                label: live.rainLabel,
                                trend: _trend(live.rain, previous?.rain, 0.1),
                              ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'KETINGGIAN AIR',
                                unit: 'cm',
                                value: live.distance,
                                minVal: 0,
                                maxVal: 400,
                                color: AppTheme.colDist,
                                icon: Icons.waves_rounded,
                                label: live.distanceLabel,
                                trend: _trend(live.distance, previous?.distance, 2.0),
                              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.15),
                            ),
                            RepaintBoundary(
                              child: SensorCard(
                                title: 'BATERAI',
                                unit: 'V',
                                value: live.battery,
                                minVal: 8,
                                maxVal: 14,
                                color: AppTheme.colBatt,
                                icon: Icons.battery_charging_full_rounded,
                                label: live.batteryLabel,
                                trend: _trend(live.battery, previous?.battery, 0.2),
                                compareValue: '${((live.battery - 9.0) / (12.6 - 9.0) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.15),
                            ),
                          ]),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      if (kDebugMode) ...[
                        const SliverToBoxAdapter(
                          child: _SectionLabel(
                            title: 'Simulasi Data (Debug)',
                            subtitle: 'Uji respon aplikasi terhadap skenario cuaca ekstrem tanpa hardware',
                            icon: Icons.science_rounded,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
                        const SliverToBoxAdapter(child: _TestPanel()),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
      ..color = AppTheme.heroAcc.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

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

  static (Color, IconData, String, String) _riskStyle(String level) {
    switch (level) {
      case 'RENDAH':
        return (AppTheme.online, Icons.verified_user_rounded, 'Aman', 'Risiko banjir rendah. Kondisi terpantau normal.');
      case 'SEDANG':
        return (AppTheme.warning, Icons.info_rounded, 'Waspada', 'Risiko sedang. Pantau ketinggian air secara berkala.');
      case 'TINGGI':
        return (const Color(0xFFEA580C), Icons.warning_amber_rounded, 'Siaga', 'Risiko tinggi. Siapkan langkah antisipasi banjir.');
      case 'KRITIS':
        return (AppTheme.offline, Icons.crisis_alert_rounded, 'Bahaya', 'Kondisi kritis! Segera lakukan evakuasi bila perlu.');
      default:
        return (AppTheme.heroAcc, Icons.radar_rounded, 'Menganalisis', 'Menunggu data cukup untuk menilai risiko banjir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = context.select<AppState, String>((s) => s.floodRiskLevel);
    final (riskColor, riskIcon, riskTitle, riskDesc) = _riskStyle(riskLevel);
    final statusText = locationLoading ? 'Mencari Lokasi...' : locationName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [riskColor, Color.lerp(riskColor, AppTheme.colDist, 0.45)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: riskColor.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -18,
                  top: -18,
                  child: Icon(
                    Icons.water_rounded,
                    size: 110,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(riskIcon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS RISIKO BANJIR',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              Text(
                                riskTitle,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      riskDesc,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(Icons.location_on_rounded, statusText),
                        _pill(Icons.sensors_rounded, online ? 'ESP32 Terhubung' : 'ESP32 Terputus',
                            dot: online ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5)),
                        _pill(Icons.cloud_sync_rounded,
                            internet != null ? 'OpenWeather Aktif' : 'Sinkronisasi...'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
          const SizedBox(height: 12),
          Material(
            color: AppTheme.cardSolid,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const AiChatPanel(),
                );
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppTheme.heroAcc, AppTheme.colPres],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanya ParaBot AI',
                            style: GoogleFonts.outfit(
                              color: AppTheme.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '"Apakah hari ini aman dari banjir?"',
                            style: GoogleFonts.outfit(color: AppTheme.subtext, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.heroAcc.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.heroAcc, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 350.ms),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, {Color? dot}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
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
  final IconData icon;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
    this.icon = Icons.insights_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.heroAcc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.heroAcc, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
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

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _greeting(int hour) {
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
    final statusColor = online ? AppTheme.online : AppTheme.offline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.heroAcc.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                'assets/images/splashscreen.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/splashscreen.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) {
                      return const Icon(Icons.domain_rounded, color: AppTheme.heroAcc, size: 22);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting(now.hour)} 👋',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$dateText · ParamaFlood',
                  style: GoogleFonts.outfit(color: AppTheme.subtext, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.35, end: 1, duration: 900.ms),
                const SizedBox(width: 6),
                Text(
                  online ? 'LIVE' : 'OFFLINE',
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppTheme.cardSolid,
            shape: const CircleBorder(side: BorderSide(color: AppTheme.cardBorder)),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.heroAcc, size: 20),
              tooltip: 'Muat ulang',
              onPressed: onRefresh,
            ),
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
    ('Panas & Lembab', Icons.sunny, _wd(38.5, 85, 1008, 2.1, 45000, 0.0, 110.0, 12.4)),
    ('Dingin & Kering', Icons.ac_unit_rounded, _wd(4.2, 22, 1025, 0.4, 25000, 0.0, 80.0, 11.2)),
    ('Badai Hujan', Icons.thunderstorm_rounded, _wd(16, 95, 978, 14.5, 150, 4.2, 40.0, 12.0)),
    ('Normal Sejuk', Icons.wb_cloudy_rounded, _wd(22, 55, 1013, 3.2, 32000, 0.0, 120.0, 12.6)),
    ('Ismailia', Icons.location_city_rounded, _wd(28.5, 42, 1011, 4.3, 55000, 0.0, 95.0, 12.2)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.heroAcc.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.heroAcc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.science_rounded, color: AppTheme.heroAcc, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulator Skenario Cuaca',
                          style: GoogleFonts.outfit(
                            color: AppTheme.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _expanded ? 'Pilih preset data di bawah ini' : 'Ketuk untuk membuka pilihan preset',
                          style: GoogleFonts.outfit(
                            color: AppTheme.subtext,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.heroAcc,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) => _btn(context, preset.$1, preset.$2, preset.$3)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, IconData icon, WeatherData data) {
    return GestureDetector(
      onTap: () async {
        await context.read<AppState>().pushTestData(data);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data Disimulasikan: $label',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppTheme.heroAcc,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.heroAcc.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.heroAcc.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.heroAcc),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.heroAcc,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
