import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/siren_service.dart';
import '../services/voice_alert_service.dart';

class WaterCanalVisualizer extends StatefulWidget {
  final double waterLevelCm;     // Real-time sensor water level (cm)
  final double rainRateMm;       // Rain rate for particle splash intensity
  final double windSpeedMs;      // Wind speed influencing wave turbulence
  final String floodRiskLevel;   // RENDAH, SEDANG, TINGGI, KRITIS
  final VoidCallback? onSpeakAlert;

  const WaterCanalVisualizer({
    super.key,
    required this.waterLevelCm,
    this.rainRateMm = 0.0,
    this.windSpeedMs = 0.0,
    this.floodRiskLevel = 'RENDAH',
    this.onSpeakAlert,
  });

  @override
  State<WaterCanalVisualizer> createState() => _WaterCanalVisualizerState();
}

class _WaterCanalVisualizerState extends State<WaterCanalVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  // Simulation mode for thesis defense / live interactive demonstration
  bool _isSimulationMode = false;
  double _simulatedWaterLevel = 45.0;

  static const double canalMaxDepthCm = 100.0; // Canal depth threshold (100 cm capacity)

  @override
  void dispose() {
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double get _effectiveWaterLevel =>
      _isSimulationMode ? _simulatedWaterLevel : widget.waterLevelCm;

  Color _getStatusColor(double level) {
    if (level >= 85.0 || widget.floodRiskLevel == 'KRITIS') {
      return AppTheme.offline; // Red
    } else if (level >= 70.0 || widget.floodRiskLevel == 'TINGGI') {
      return const Color(0xFFF97316); // Orange
    } else if (level >= 50.0 || widget.floodRiskLevel == 'SEDANG') {
      return AppTheme.warning; // Amber
    }
    return AppTheme.heroAcc; // Cyan / Water Blue
  }

  String _getStatusText(double level) {
    if (level >= 85.0) return 'BAHAYA LUAPAN';
    if (level >= 70.0) return 'SIAGA BANJIR';
    if (level >= 50.0) return 'WASPADA';
    return 'NORMAL / AMAN';
  }

  @override
  Widget build(BuildContext context) {
    final waterLevel = _effectiveWaterLevel;
    final statusColor = _getStatusColor(waterLevel);
    final statusText = _getStatusText(waterLevel);
    final freeboardCm = (canalMaxDepthCm - waterLevel).clamp(0.0, canalMaxDepthCm);
    final fillFraction = (waterLevel / canalMaxDepthCm).clamp(0.08, 1.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: waterLevel >= 70
              ? statusColor.withValues(alpha: 0.5)
              : AppTheme.cardBorder,
          width: waterLevel >= 70 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: waterLevel >= 70 ? 0.15 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.waves_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIMULATOR PENAMPANG KANAL AIR',
                        style: GoogleFonts.outfit(
                          color: AppTheme.heroAcc,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Drainase Kampus Universitas Paramadina',
                        style: GoogleFonts.outfit(
                          color: AppTheme.subtext,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Speaker Audio Broadcast Button
                IconButton(
                  onPressed: () {
                    VoiceAlertService.speakFloodAlert(
                      waterLevelCm: waterLevel,
                      riskLevel: statusText,
                      force: true,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: Row(
                          children: [
                            const Icon(Icons.volume_up_rounded,
                                color: AppTheme.heroAcc, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Menyiarkan narasi suara kondisi kanal...',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppTheme.heroAcc,
                    size: 20,
                  ),
                  tooltip: 'Siarkan Peringatan Suara',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.heroAcc.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),

          // ── Status Chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.outfit(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Freeboard capacity badge
                Text(
                  'Sisa Kapasitas: ${freeboardCm.toStringAsFixed(1)} cm',
                  style: GoogleFonts.outfit(
                    color: freeboardCm < 20 ? AppTheme.offline : AppTheme.subtext,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // 🚨 Active Air Raid Siren Banner (When water is within 20cm of sensor tip)
          ValueListenableBuilder<bool>(
            valueListenable: SirenService.isSirenActiveNotifier,
            builder: (context, isActive, _) {
              if (!isActive) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.offline.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.offline, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.offline.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: AppTheme.offline, size: 22)
                        .animate(onPlay: (c) => c.repeat())
                        .shake(duration: 400.ms),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AIR RAID SIREN AKTIF! (Air ≤ 20cm dari Sensor)',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Air menyentuh batas puncak kanal. Sirine meraung!',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        SirenService.muteSiren();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.offline,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MUTE',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2);
            },
          ),

          const SizedBox(height: 12),

          // ── Animated 2D Canal Physics Canvas ──
          Container(
            height: 190,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF070D18), // Deep underwater canal base
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  // Animated Wave Canvas
                  AnimatedBuilder(
                    animation: Listenable.merge([_waveCtrl, _pulseCtrl]),
                    builder: (context, _) {
                      return CustomPaint(
                        size: const Size(double.infinity, 190),
                        painter: _CanalWavePainter(
                          waveProgress: _waveCtrl.value,
                          pulseProgress: _pulseCtrl.value,
                          fillFraction: fillFraction,
                          statusColor: statusColor,
                          windFactor: (widget.windSpeedMs / 15.0).clamp(0.2, 1.5),
                        ),
                      );
                    },
                  ),

                  // Canal Embankment & Depth Ruler Overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CanalRulerPainter(
                        waterLevelCm: waterLevel,
                        maxDepthCm: canalMaxDepthCm,
                        statusColor: statusColor,
                      ),
                    ),
                  ),

                  // Floating Water Elevation Tag
                  Positioned(
                    bottom: (190 * fillFraction).clamp(24.0, 160.0),
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.straighten_rounded,
                              size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            '${waterLevel.toStringAsFixed(1)} cm',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overflow Warning Banner (if level > 85cm)
                  if (waterLevel >= 85.0)
                    Positioned(
                      top: 10,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.offline.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'BAHAYA LUAPAN',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 500.ms),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Interactive Simulation / Demo Slider Toggle ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSimulationMode = !_isSimulationMode;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isSimulationMode
                          ? AppTheme.heroAcc.withValues(alpha: 0.12)
                          : AppTheme.bgAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isSimulationMode
                            ? AppTheme.heroAcc.withValues(alpha: 0.4)
                            : AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSimulationMode
                              ? Icons.tune_rounded
                              : Icons.science_outlined,
                          size: 16,
                          color: _isSimulationMode
                              ? AppTheme.heroAcc
                              : AppTheme.subtext,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSimulationMode
                              ? 'Mode Simulasi Aktif (Geser untuk Uji Coba)'
                              : 'Buka Slider Simulasi Interaktif (Demo Sidang)',
                          style: GoogleFonts.outfit(
                            color: _isSimulationMode
                                ? AppTheme.heroAcc
                                : AppTheme.subtext,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isSimulationMode
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.subtext,
                        ),
                      ],
                    ),
                  ),
                ),

                // Interactive slider when simulation mode is active
                if (_isSimulationMode) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Level Air Uji: ${_simulatedWaterLevel.toStringAsFixed(0)} cm',
                        style: GoogleFonts.outfit(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '0 cm — 100 cm',
                        style: GoogleFonts.outfit(
                          color: AppTheme.subtext,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: statusColor,
                      inactiveTrackColor: AppTheme.cardBorder,
                      thumbColor: statusColor,
                      overlayColor: statusColor.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _simulatedWaterLevel,
                      min: 5.0,
                      max: 100.0,
                      onChanged: (val) {
                        setState(() {
                          _simulatedWaterLevel = val;
                        });
                        // Trigger Air Raid Siren when water reaches within 20cm of sensor tip (>= 80cm)
                        if (val >= 80.0) {
                          SirenService.unmute();
                          SirenService.startAirRaidSiren();
                          VoiceAlertService.speakFloodAlert(
                            waterLevelCm: val,
                            riskLevel: 'KRITIS',
                          );
                        } else if (val < 75.0 && SirenService.isPlaying) {
                          SirenService.stopAirRaidSiren();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dual Sine-Wave Liquid Painter ──────────────────────────────────
class _CanalWavePainter extends CustomPainter {
  final double waveProgress;
  final double pulseProgress;
  final double fillFraction;
  final Color statusColor;
  final double windFactor;

  _CanalWavePainter({
    required this.waveProgress,
    required this.pulseProgress,
    required this.fillFraction,
    required this.statusColor,
    required this.windFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseHeight = size.height * (1.0 - fillFraction);
    final waveAmplitude = (6.0 * windFactor).clamp(3.0, 14.0);

    // 1. Background Translucent Wave (Slower, shifted phase)
    final backWavePath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseHeight +
          math.sin((x / size.width * 2 * math.pi) + (waveProgress * 2 * math.pi) + 1.2) *
              (waveAmplitude * 0.7);
      backWavePath.lineTo(x, y);
    }
    backWavePath.lineTo(size.width, size.height);
    backWavePath.close();

    final backPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(backWavePath, backPaint);

    // 2. Foreground Vibrant Wave (Fast, dynamic gradient)
    final frontWavePath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseHeight +
          math.sin((x / size.width * 2.5 * math.pi) - (waveProgress * 2 * math.pi)) *
              waveAmplitude;
      frontWavePath.lineTo(x, y);
    }
    frontWavePath.lineTo(size.width, size.height);
    frontWavePath.close();

    final frontGradient = LinearGradient(
      colors: [
        statusColor.withValues(alpha: 0.85),
        statusColor.withValues(alpha: 0.60),
        const Color(0xFF030712),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final frontPaint = Paint()
      ..shader = frontGradient.createShader(
        Rect.fromLTWH(0, baseHeight - 10, size.width, size.height - baseHeight + 10),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(frontWavePath, frontPaint);

    // 3. Glowing Water Surface Crest Line
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final crestPath = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final y = baseHeight +
          math.sin((x / size.width * 2.5 * math.pi) - (waveProgress * 2 * math.pi)) *
              waveAmplitude;
      if (x == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }
    canvas.drawPath(crestPath, crestPaint);
  }

  @override
  bool shouldRepaint(covariant _CanalWavePainter oldDelegate) => true;
}

// ─── Canal Cross-Section Depth Ruler Overlay Painter ─────────────────
class _CanalRulerPainter extends CustomPainter {
  final double waterLevelCm;
  final double maxDepthCm;
  final Color statusColor;

  _CanalRulerPainter({
    required this.waterLevelCm,
    required this.maxDepthCm,
    required this.statusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw Depth Ruler Ticks on the left embankment (0 to 100 cm)
    final rulerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (int cm = 0; cm <= 100; cm += 20) {
      final fraction = cm / maxDepthCm;
      final y = size.height * (1.0 - fraction);

      // Major Tick
      canvas.drawLine(Offset(12, y), Offset(22, y), rulerPaint);

      textPainter.text = TextSpan(
        text: '$cm',
        style: GoogleFonts.outfit(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(26, y - 5));
    }

    // Overflow Limit Line at 90% (85-100cm)
    final overflowY = size.height * (1.0 - (85.0 / maxDepthCm));
    final overflowPaint = Paint()
      ..color = AppTheme.offline.withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Draw dashed overflow line
    double startX = 12;
    while (startX < size.width - 12) {
      canvas.drawLine(
        Offset(startX, overflowY),
        Offset(startX + 5, overflowY),
        overflowPaint,
      );
      startX += 9;
    }

    // Overflow text label
    textPainter.text = TextSpan(
      text: 'AMBANG BAHAYA (85 cm)',
      style: GoogleFonts.outfit(
        color: AppTheme.offline,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 14, overflowY - 12));
  }

  @override
  bool shouldRepaint(covariant _CanalRulerPainter oldDelegate) =>
      oldDelegate.waterLevelCm != waterLevelCm ||
      oldDelegate.statusColor != statusColor;
}
