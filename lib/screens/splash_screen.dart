import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_theme.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _riseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final Animation<double> _riseAnim = CurvedAnimation(
    parent: _riseCtrl,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            seen ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _riseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Background gradient ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.bg,
                    AppTheme.bgAlt,
                    AppTheme.colDist.withOpacity(0.08),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Animated water waves ──
          AnimatedBuilder(
            animation: Listenable.merge([_waveCtrl, _riseCtrl]),
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _SplashWavePainter(
                  animationValue: _waveCtrl.value,
                  fillPercentage: _riseAnim.value * 0.35,
                ),
              );
            },
          ),

          // ── Glow orb top-left ──
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.colDist.withOpacity(0.2),
                    AppTheme.colDist.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Glow orb bottom-right ──
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.heroAcc.withOpacity(0.15),
                    AppTheme.heroAcc.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Center content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Splash Screen Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppTheme.colDist.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.colDist.withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/splashscreen.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: 28),

                // App title
                Text(
                  'PARAMAFLOOD',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, duration: 600.ms),
                const SizedBox(height: 4),
                Text(
                  'MONITOR',
                  style: GoogleFonts.outfit(
                    color: AppTheme.heroAcc,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 8,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms)
                    .slideY(begin: 0.3, duration: 600.ms),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'ESP32 IoT Flood Monitoring System',
                  style: GoogleFonts.outfit(
                    color: AppTheme.subtext,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
                const SizedBox(height: 40),

                // Loading indicator
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.heroAcc.withOpacity(0.6),
                  ),
                ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
              ],
            ),
          ),

          // ── Bottom credit ──
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Universitas Paramadina · 2026',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppTheme.subtext.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 500.ms),
          ),
        ],
      ),
    );
  }
}

// ─── Wave painter for splash ────────────────────────────────────────
class _SplashWavePainter extends CustomPainter {
  final double animationValue;
  final double fillPercentage;

  _SplashWavePainter({
    required this.animationValue,
    required this.fillPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercentage <= 0.01) return;

    final waterHeight = size.height * fillPercentage;
    final yOffset = size.height - waterHeight;

    // Back wave
    final paint1 = Paint()
      ..color = AppTheme.colDist.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.lineTo(0, yOffset);
    for (double i = 0; i <= size.width; i += 4) {
      path1.lineTo(
        i,
        yOffset +
            sin((i / size.width * 3 * pi) + (animationValue * 2 * pi)) * 14,
      );
    }
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Front wave
    final paint2 = Paint()
      ..color = AppTheme.colDist.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.lineTo(0, yOffset + 10);
    for (double i = 0; i <= size.width; i += 4) {
      path2.lineTo(
        i,
        yOffset +
            10 +
            sin((i / size.width * 2 * pi) - (animationValue * 2 * pi) + pi) *
                10,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _SplashWavePainter old) {
    return old.animationValue != animationValue ||
        old.fillPercentage != fillPercentage;
  }
}
