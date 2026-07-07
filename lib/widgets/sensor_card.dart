import 'dart:math';
import 'dart:ui';
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
    this.compareValue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              // Inner glow top edge
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.25), color],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                // ── Header row: title + trend ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.outfit(
                                color: color,
                                fontSize: 11,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Realtime channel',
                            style: GoogleFonts.outfit(
                                color: AppTheme.subtext,
                                fontSize: 8,
                                letterSpacing: 0.8)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(trend,
                          style: GoogleFonts.outfit(
                              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                // ── Premium Arc gauge ─────────────────────────────────────
                Expanded(
                  child: CustomPaint(
                    painter: _PremiumArcPainter(pct: pct, color: color),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            key: ValueKey(value.toStringAsFixed(1)),
                            children: [
                              Text(
                                value.toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                    color: AppTheme.text,
                                fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5),
                              ),
                              Text(
                                unit.trim(),
                                style: GoogleFonts.outfit(
                                    color: color.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Label ──────────────────────────────────────────
                Text(label,
                    style: GoogleFonts.outfit(
                        color: AppTheme.subtext,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2)),

                // ── Firebase / Internet compare badge ─────────────
                if (compareValue != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.internet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.internet.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_sync_outlined, size: 10, color: AppTheme.internet),
                        const SizedBox(width: 4),
                        Text(compareValue!,
                            style: GoogleFonts.outfit(
                                color: AppTheme.internet, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Premium Arc gauge painter ────────────────────────────────────────
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
          ..color = color.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      
      // Main arc with gradient
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweep,
        colors: [color.withOpacity(0.6), color],
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
          Offset(cx + r * cos(na), cy + r * sin(na)), 4,
          Paint()..color = Colors.white
                 ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
    }
  }

  @override
  bool shouldRepaint(_PremiumArcPainter o) => o.pct != pct || o.color != color;
}
