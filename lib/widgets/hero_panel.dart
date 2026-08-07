import 'dart:math';
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

class _HeroPanelState extends State<HeroPanel> with SingleTickerProviderStateMixin {
  late final Stream<int> _ticker =
      Stream.periodic(const Duration(seconds: 1), (i) => i);
      
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Assuming 400cm is empty (0% filled) and 0cm is overflowing (100% filled)
    final fillPct = ((400 - widget.live.distance) / 400).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Stack(
            children: [
              // Canal Wave Visualization Background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _WaterWavePainter(
                        fillPercentage: fillPct,
                        animationValue: _waveCtrl.value,
                      ),
                    );
                  },
                ),
              ),
              
              // Main Content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.25),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.heroAcc.withValues(alpha: 0.10),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
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
                                  const Icon(Icons.location_on_rounded, color: AppTheme.heroAcc, size: 15),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: widget.locationLoading
                                        ? Text(
                                            'Mencari lokasi...',
                                            style: GoogleFonts.outfit(
                                              color: AppTheme.heroAcc.withValues(alpha: 0.6),
                                              fontSize: 11,
                                              letterSpacing: 1.0,
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
                                                    style: GoogleFonts.outfit(
                                                      color: _locationColor,
                                                      fontSize: 11,
                                                      letterSpacing: 0.8,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (_showRetryIcon) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    widget.locationDeniedForever ? Icons.settings_outlined : Icons.refresh,
                                                    color: AppTheme.offline,
                                                    size: 12,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sistem Monitoring Ketinggian Air',
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
                          style: GoogleFonts.outfit(
                            color: widget.isOnline ? AppTheme.online : AppTheme.offline,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
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
                                    widget.live.distance.toStringAsFixed(0),
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.text,
                                      fontSize: 62,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -2.0,
                                      height: 0.95,
                                    ),
                                  ).animate(key: ValueKey(widget.live.distance.toStringAsFixed(0))).scaleXY(begin: 0.9, duration: 300.ms, curve: Curves.easeOutBack).fadeIn(duration: 250.ms),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 4),
                                    child: Text(
                                      'cm',
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.heroAcc,
                                        fontSize: 22,
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
                                   color: Colors.white.withValues(alpha: 0.90),
                                   borderRadius: BorderRadius.circular(999),
                                   border: Border.all(color: _statusColor(widget.live.distanceLabel).withValues(alpha: 0.6), width: 1.2),
                                   boxShadow: [
                                     BoxShadow(
                                       color: _statusColor(widget.live.distanceLabel).withValues(alpha: 0.15),
                                       blurRadius: 8,
                                       offset: const Offset(0, 2),
                                     ),
                                   ],
                                 ),
                                 child: Text(
                                   widget.live.distanceLabel.toUpperCase(),
                                   style: GoogleFonts.outfit(
                                     color: _statusColor(widget.live.distanceLabel),
                                     fontSize: 10,
                                     letterSpacing: 1.5,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                              const SizedBox(height: 6),
                              Text(
                                'Jarak Permukaan Air Ke Sensor',
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
                                  DateFormat('HH:mm:ss').format(now),
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMM').format(now),
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.subtext,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                  if (widget.internet != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.90),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: AppTheme.heroAcc.withValues(alpha: 0.35)),
                                      ),
                                      child: Text(
                                        '${widget.internet!.temp.toStringAsFixed(1)}°C  ${widget.internet!.conditionEmoji}',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.heroAcc,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
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
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(Icons.thermostat_rounded, '${widget.live.temp.toStringAsFixed(1)}°C'),
                        _chip(Icons.water_drop_rounded, '${widget.live.hum.toStringAsFixed(0)}%'),
                        _chip(Icons.air_rounded, '${widget.live.wind.toStringAsFixed(1)} m/s'),
                        _chip(Icons.compress_rounded, '${(widget.live.pres / 10).toStringAsFixed(1)} kPa'),
                        _chip(Icons.sync_rounded, '#${widget.frameCount % 9999}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
  
  Color _statusColor(String label) {
    if (label == 'SAFE') return AppTheme.colDist;
    if (label == 'HIGH LVL') return AppTheme.warning;
    if (label == 'WARNING') return AppTheme.colTemp;
    if (label == 'CRITICAL') return AppTheme.offline;
    return AppTheme.heroAcc;
  }

  Widget _chip(IconData icon, String val) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppTheme.heroAcc.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.heroAcc),
            const SizedBox(width: 6),
            Text(
              val,
              style: GoogleFonts.outfit(
                color: AppTheme.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
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
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 6)]),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .fadeOut(duration: 900.ms)
        .then()
        .fadeIn(duration: 900.ms);
  }
}

class _WaterWavePainter extends CustomPainter {
  final double fillPercentage;
  final double animationValue;

  _WaterWavePainter({required this.fillPercentage, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0.02) return; // Don't draw if basically empty

    final waterHeight = size.height * fillPercentage;
    final yOffset = size.height - waterHeight;

    final paint1 = Paint()
      ..color = AppTheme.heroAcc.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppTheme.heroAcc.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Draw background wave
    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.lineTo(0, yOffset);
    for (double i = 0; i <= size.width; i += 4) {
      path1.lineTo(i, yOffset + sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 8);
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Draw foreground wave
    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.lineTo(0, yOffset);
    for (double i = 0; i <= size.width; i += 4) {
      path2.lineTo(i, yOffset + sin((i / size.width * 2 * pi) - (animationValue * 2 * pi) + pi) * 12);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage || oldDelegate.animationValue != animationValue;
  }
}
