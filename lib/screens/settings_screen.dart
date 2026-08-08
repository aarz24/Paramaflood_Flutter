import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            bottom: -60,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.heroAcc.withOpacity(0.1),
                      AppTheme.heroAcc.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(child: _Header()),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── App Info Card ──
                SliverToBoxAdapter(
                  child: _InfoCard(
                    title: 'ABOUT',
                    children: [
                      _InfoRow(
                          icon: Icons.water_drop_rounded,
                          label: 'App Name',
                          value: 'ParamaFlood Monitor'),
                      _InfoRow(
                          icon: Icons.tag_rounded,
                          label: 'Version',
                          value: '2.0.0 (Phase 1)'),
                      _InfoRow(
                          icon: Icons.memory_rounded,
                          label: 'Platform',
                          value: 'ESP32 + Flutter + Firebase'),
                      _InfoRow(
                          icon: Icons.school_rounded,
                          label: 'Institution',
                          value: 'Universitas Paramadina'),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Team Card ──
                SliverToBoxAdapter(
                  child: _InfoCard(
                    title: 'TEAM',
                    children: [
                      _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Researcher',
                          value: 'Arya'),
                      _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Researcher',
                          value: 'Aril'),
                      _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Researcher',
                          value: 'Naina'),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Location Card ──
                SliverToBoxAdapter(
                  child: Consumer<AppState>(
                    builder: (context, state, _) {
                      return _InfoCard(
                        title: 'DEVICE LOCATION',
                        children: [
                          _InfoRow(
                            icon: Icons.place_rounded,
                            label: 'Location',
                            value: state.locationName,
                          ),
                          _InfoRow(
                            icon: Icons.sensors_rounded,
                            label: 'Sensor Status',
                            value: state.live.isOnline
                                ? 'Online'
                                : 'Offline',
                            valueColor: state.live.isOnline
                                ? AppTheme.online
                                : AppTheme.offline,
                          ),
                        ],
                        action: state.locationDeniedForever
                            ? _ActionButton(
                                label: 'Open Settings',
                                icon: Icons.settings_rounded,
                                onTap: () => state.openAppSettings(),
                              )
                            : (state.locationName == 'GPS Off' ||
                                    state.locationName == 'Location Denied' ||
                                    state.locationName == 'Location Error' ||
                                    state.locationName == 'GPS Timeout')
                                ? _ActionButton(
                                    label: 'Retry Location',
                                    icon: Icons.refresh_rounded,
                                    onTap: () => state.retryLocation(),
                                  )
                                : null,
                      );
                    },
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // ── Phase 2 Preview ──
                SliverToBoxAdapter(
                  child: _Phase2Card()
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.1),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.heroAcc.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.heroAcc.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.heroAcc.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/splashscreen.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/splashscreen.png',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) {
                      return const Icon(
                        Icons.settings_rounded,
                        color: AppTheme.heroAcc,
                        size: 22,
                      );
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
                  'Settings',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'App info, location, and configuration',
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

// ─── Reusable info card ──────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> children;
  final Widget? action;

  const _InfoCard({
    required this.title,
    required this.children,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.heroAcc.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppTheme.heroAcc,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...children.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: row,
              )),
          if (action != null) ...[
            const SizedBox(height: 4),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─── Single info row ────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.subtext.withOpacity(0.6), size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.subtext,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              color: valueColor ?? AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─── Action button ──────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.heroAcc.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.heroAcc.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.heroAcc, size: 14),
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

// ─── Phase 2 preview card ────────────────────────────────────────────
class _Phase2Card extends StatelessWidget {
  static const _upcoming = [
    (Icons.notifications_active_rounded, 'Push Notifications',
        'Real-time flood alerts via FCM'),
    (Icons.psychology_rounded, 'LSTM Predictions',
        'AI-powered water level forecasting'),
    (Icons.download_rounded, 'Data Export',
        'Export history to CSV / PDF'),
    (Icons.translate_rounded, 'Bahasa Indonesia',
        'Full app localization'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.heroAcc.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'COMING IN PHASE 2',
                style: GoogleFonts.outfit(
                  color: AppTheme.heroAcc,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.heroAcc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'NEXT SEMESTER',
                  style: GoogleFonts.outfit(
                    color: AppTheme.heroAcc,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._upcoming.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.subtext.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.$1,
                          color: AppTheme.subtext.withOpacity(0.4),
                          size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: GoogleFonts.outfit(
                              color: AppTheme.subtext.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.$3,
                            style: GoogleFonts.outfit(
                              color: AppTheme.subtext.withOpacity(0.35),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded,
                        color: AppTheme.subtext.withOpacity(0.2), size: 14),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
