
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/weather_data.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';
import '../widgets/analytics_panel.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Background gradient ──
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

          // ── Subtle glow ──
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.colDist.withValues(alpha: 0.10),
                      AppTheme.colDist.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Selector<AppState, _HistoryData>(
              selector: (_, state) => _HistoryData(
                live: state.live,
                internet: state.internet,
                history: state.history,
              ),
              shouldRebuild: (prev, next) => prev != next,
              builder: (context, data, _) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: _Header(readings: data.history.length),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: _SummaryStrip(history: data.history)
                          .animate()
                          .fadeIn(delay: 60.ms)
                          .slideY(begin: 0.08),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Trending History ──
                    const SliverToBoxAdapter(
                      child: _SectionLabel(
                        title: 'Tren Riwayat',
                        icon: Icons.show_chart_rounded,
                        subtitle:
                            'Riwayat sensor dari pembacaan terakhir',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: HistoryChart(history: data.history)
                            .animate()
                            .fadeIn(delay: 100.ms),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Live Comparison ──
                    const SliverToBoxAdapter(
                      child: _SectionLabel(
                        title: 'Perbandingan Langsung',
                        icon: Icons.compare_arrows_rounded,
                        subtitle:
                            'Data sensor dibandingkan dengan Open-Meteo',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ComparisonPanel(
                              sensor: data.live, internet: data.internet)
                          .animate()
                          .fadeIn(delay: 150.ms),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Insights ──
                    const SliverToBoxAdapter(
                      child: _SectionLabel(
                        title: 'Wawasan Cuaca',
                        icon: Icons.lightbulb_rounded,
                        subtitle:
                            'Pemeriksaan cepat dan interpretasi cuaca',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: WeatherAnalyticsPanel(
                        sensor: data.live,
                        internet: data.internet,
                        history: data.history,
                      ).animate().fadeIn(delay: 200.ms),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data selector ──────────────────────────────────────────────────
class _HistoryData {
  final WeatherData live;
  final InternetWeather? internet;
  final List<WeatherData> history;

  const _HistoryData({
    required this.live,
    required this.internet,
    required this.history,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _HistoryData &&
        live.timestamp == other.live.timestamp &&
        listEquals(history, other.history) &&
        internet?.fetchedAt == other.internet?.fetchedAt;
  }

  @override
  int get hashCode =>
      Object.hash(live.timestamp, Object.hashAll(history), internet?.fetchedAt);
}

// ─── Header ──────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int readings;

  const _Header({required this.readings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppTheme.colDist, AppTheme.heroAcc],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.heroAcc.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.timeline_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat & Analitik',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Tren, perbandingan, dan wawasan cuaca',
                  style: GoogleFonts.outfit(color: AppTheme.subtext, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.heroAcc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$readings data',
              style: GoogleFonts.outfit(
                color: AppTheme.heroAcc,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary strip ──────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final List<WeatherData> history;

  const _SummaryStrip({required this.history});

  @override
  Widget build(BuildContext context) {
    final hasData = history.isNotEmpty;
    double avg(double Function(WeatherData) f) =>
        history.map(f).reduce((a, b) => a + b) / history.length;
    double maxOf(double Function(WeatherData) f) =>
        history.map(f).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _stat(Icons.thermostat_rounded, 'Rata-rata Suhu',
              hasData ? '${avg((d) => d.temp).toStringAsFixed(1)}°C' : '—', AppTheme.colTemp),
          const SizedBox(width: 10),
          _stat(Icons.grain_rounded, 'Hujan Maks',
              hasData ? '${maxOf((d) => d.rain).toStringAsFixed(1)} mm' : '—', AppTheme.colRain),
          const SizedBox(width: 10),
          _stat(Icons.water_drop_rounded, 'Rata-rata RH',
              hasData ? '${avg((d) => d.hum).toStringAsFixed(0)}%' : '—', AppTheme.colHum),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardSolid,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  color: AppTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(color: AppTheme.subtext, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
