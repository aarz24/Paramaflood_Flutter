import 'dart:ui';

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
                      AppTheme.colPres.withOpacity(0.12),
                      AppTheme.colPres.withOpacity(0.0),
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
                      child: _Header(),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ── Trending History ──
                    const SliverToBoxAdapter(
                      child: _SectionLabel(
                        title: 'TRENDING HISTORY',
                        subtitle:
                            'Rolling sensor history across the last readings',
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
                        title: 'LIVE COMPARISON',
                        subtitle:
                            'Sensor readings against Open-Meteo for context',
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
                        title: 'INSIGHTS',
                        subtitle:
                            'Quick health checks and weather interpretation',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: WeatherAnalyticsPanel(
                        sensor: data.live,
                        internet: data.internet,
                        history: data.history,
                      ).animate().fadeIn(delay: 200.ms),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.card.withOpacity(0.72),
            AppTheme.cardSolid.withOpacity(0.92),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppTheme.colPres.withOpacity(0.25),
                  AppTheme.heroAcc.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.timeline_rounded,
                color: AppTheme.text, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'History & Analytics',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trends, comparisons, and weather insights',
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
    );
  }
}

// ─── Section label (reused from dashboard) ──────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
