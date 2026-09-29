import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String unit;
  final double value;
  final double minVal;
  final double maxVal;
  final Color color;
  final String label;
  final String trend;
  final IconData? icon;
  final String? compareValue;

  const SensorCard({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    required this.minVal,
    required this.maxVal,
    required this.color,
    required this.label,
    required this.trend,
    this.icon,
    this.compareValue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

    final trendIcon = switch (trend) {
      '↑' => Icons.trending_up_rounded,
      '↓' => Icons.trending_down_rounded,
      _ => Icons.trending_flat_rounded,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(color.withValues(alpha: 0.08), AppTheme.cardSolid),
              AppTheme.cardSolid,
            ],
            begin: Alignment.topCenter,
            end: const Alignment(0, 0.1),
          ),
          color: AppTheme.cardSolid,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Header row: Icon badge + Title + Trend ───────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 16, color: color),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: color,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Sensor ESP32',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: AppTheme.subtext,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(trendIcon, size: 14, color: color),
                  ),
                ],
              ),

              // ── Arc gauge ─────────────────────────────────────
              Expanded(
                child: CustomPaint(
                  painter: _PremiumArcPainter(pct: pct, color: color),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          key: ValueKey(value.toStringAsFixed(1)),
                          children: [
                            Text(
                              value.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                color: AppTheme.text,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              unit.trim(),
                              style: GoogleFonts.outfit(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Label ──────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // ── OpenWeather Compare Badge ──────────────────────
              if (compareValue != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.internet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.internet.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_sync_outlined,
                          size: 11, color: AppTheme.internet),
                      const SizedBox(width: 4),
                      Text(
                        'OpenWeather: $compareValue',
                        style: GoogleFonts.outfit(
                          color: AppTheme.internet,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Arc gauge painter ──────────────────────────────────────────────
class _PremiumArcPainter extends CustomPainter {
  final double pct;
  final Color color;
  _PremiumArcPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = 140.0 * pi / 180;
    const sweep = 260.0 * pi / 180;
    final cx = size.width / 2;
    final cy = size.height / 2 + 8;
    final r = min(size.width, size.height) * 0.42;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Track (background arc) - very subtle
    canvas.drawArc(
      rect,
      startAngle,
      sweep,
      false,
      Paint()
        ..color = AppTheme.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    if (pct > 0.01) {
      // Glow effect behind the main arc
      canvas.drawArc(
        rect,
        startAngle,
        sweep * pct,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Main arc with gradient
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweep,
        colors: [color.withValues(alpha: 0.5), color],
        stops: const [0.0, 1.0],
      );

      canvas.drawArc(
        rect,
        startAngle,
        sweep * pct,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      // glowing tip dot
      final na = startAngle + sweep * pct;
      canvas.drawCircle(
          Offset(cx + r * cos(na), cy + r * sin(na)),
          4,
          Paint()
            ..color = AppTheme.cardSolid
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
    }
  }

  @override
  bool shouldRepaint(_PremiumArcPainter o) => o.pct != pct || o.color != color;
}
