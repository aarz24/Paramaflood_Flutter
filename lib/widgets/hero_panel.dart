import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/weather_data.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

class HeroPanel extends StatefulWidget {
  final WeatherData live;
  final InternetWeather? internet;
  final String locationName;
  final bool isOnline;
  final int frameCount;
  final bool locationLoading;
  final bool locationDeniedForever;

  const HeroPanel({
    super.key,
    required this.live,
    required this.locationName,
    required this.isOnline,
    required this.frameCount,
    this.internet,
    this.locationLoading = false,
    this.locationDeniedForever = false,
  });

  @override
  State<HeroPanel> createState() => _HeroPanelState();
}

class _HeroPanelState extends State<HeroPanel> {
  late final Stream<int> _ticker =
      Stream.periodic(const Duration(seconds: 1), (i) => i);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.heroAcc.withOpacity(0.18),
                  AppTheme.internet.withOpacity(0.08),
                  AppTheme.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 32,
                  spreadRadius: -8,
                  offset: const Offset(0, 14),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.heroAcc, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: widget.locationLoading
                                    ? Text(
                                        'Locating...',
                                        style: GoogleFonts.orbitron(
                                          color: AppTheme.heroAcc.withOpacity(0.5),
                                          fontSize: 10,
                                          letterSpacing: 1.5,
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: () {
                                          final state = context.read<AppState>();
                                          if (widget.locationDeniedForever) {
                                            state.openAppSettings();
                                          } else if (widget.locationName == 'Location Denied' ||
                                              widget.locationName == 'GPS Off' ||
                                              widget.locationName == 'Location Error') {
                                            state.retryLocation();
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                widget.locationName,
                                                style: GoogleFonts.orbitron(
                                                  color: _locationColor,
                                                  fontSize: 10,
                                                  letterSpacing: 1.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (_showRetryIcon) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                widget.locationDeniedForever ? Icons.settings_outlined : Icons.refresh,
                                                color: AppTheme.offline,
                                                size: 11,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Realtime weather overview',
                            style: GoogleFonts.outfit(
                              color: AppTheme.subtext,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusDot(isOnline: widget.isOnline),
                    const SizedBox(width: 6),
                    Text(
                      widget.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: GoogleFonts.orbitron(
                        color: widget.isOnline ? AppTheme.online : AppTheme.offline,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.live.temp.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  color: AppTheme.text,
                                  fontSize: 66,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -2.4,
                                  height: 0.95,
                                ),
                              ).animate(key: ValueKey(widget.live.temp.toStringAsFixed(1))).scaleXY(begin: 0.9, duration: 300.ms, curve: Curves.easeOutBack).fadeIn(duration: 250.ms),
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(
                                  '°C',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.heroAcc,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.heroAcc.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppTheme.heroAcc.withOpacity(0.22)),
                            ),
                            child: Text(
                              widget.live.tempLabel.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: AppTheme.heroAcc,
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Feels like ${widget.live.feelsLike.toStringAsFixed(1)}°C · ${widget.live.condition.toUpperCase()}',
                            style: GoogleFonts.outfit(
                              color: AppTheme.subtext,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<int>(
                      stream: _ticker,
                      builder: (_, __) {
                        final now = DateTime.now();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('hh:mm:ss a').format(now),
                              style: GoogleFonts.orbitron(
                                color: AppTheme.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMM d').format(now),
                              style: GoogleFonts.shareTechMono(
                                color: AppTheme.subtext,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.internet != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.internet.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppTheme.internet.withOpacity(0.35)),
                                ),
                                child: Text(
                                  '🌐 ${widget.internet!.temp.toStringAsFixed(1)}°C  ${widget.internet!.conditionEmoji}',
                                  style: GoogleFonts.orbitron(
                                    color: AppTheme.internet,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppTheme.divider, height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip(Icons.water_drop_outlined, '${widget.live.hum.toStringAsFixed(0)}%', AppTheme.colHum),
                    _chip(Icons.air, '${widget.live.wind.toStringAsFixed(1)} m/s', AppTheme.colWind),
                    _chip(Icons.speed_outlined, '${(widget.live.pres / 10).toStringAsFixed(1)} kPa', AppTheme.colPres),
                    _chip(Icons.wb_sunny_outlined, widget.live.airQualityLabel, _aqColor(widget.live.airQualityLabel)),
                    _chip(Icons.vibration, '${widget.frameCount % 9999}', AppTheme.subtext.withOpacity(0.55)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _locationColor {
    if (widget.locationName == 'GPS Off' ||
        widget.locationName == 'Location Denied' ||
        widget.locationName == 'Open Settings' ||
        widget.locationName == 'Location Error' ||
        widget.locationName == 'GPS Timeout') {
      return AppTheme.offline;
    }
    return AppTheme.heroAcc;
  }

  bool get _showRetryIcon {
    return widget.locationName == 'GPS Off' ||
        widget.locationName == 'Location Denied' ||
        widget.locationName == 'Open Settings' ||
        widget.locationName == 'Location Error' ||
        widget.locationName == 'GPS Timeout';
  }

  Widget _chip(IconData icon, String val, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.11),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
            Text(val, style: GoogleFonts.outfit(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Color _aqColor(String label) {
    if (label == 'GOOD') return AppTheme.online;
    if (label == 'MODERATE') return AppTheme.heroAcc;
    return AppTheme.offline;
  }
}

class _StatusDot extends StatelessWidget {
  final bool isOnline;
  const _StatusDot({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final c = isOnline ? AppTheme.online : AppTheme.offline;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          boxShadow: [BoxShadow(color: c.withOpacity(0.7), blurRadius: 6)]),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .fadeOut(duration: 900.ms)
        .then()
        .fadeIn(duration: 900.ms);
  }
}
