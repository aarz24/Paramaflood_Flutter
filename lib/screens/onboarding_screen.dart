import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.water_drop_rounded,
      iconColor: AppTheme.colDist,
      title: 'Monitor Water Levels',
      subtitle:
          'Real-time canal water level monitoring using ultrasonic sensors. Track rising water levels before flooding occurs.',
      accent: AppTheme.colDist,
    ),
    _OnboardingPage(
      icon: Icons.cloud_sync_outlined,
      iconColor: AppTheme.heroAcc,
      title: 'Weather Intelligence',
      subtitle:
          'Compare local ESP32 sensor readings against internet weather data from Open-Meteo. Temperature, humidity, wind — all in one view.',
      accent: AppTheme.heroAcc,
    ),
    _OnboardingPage(
      icon: Icons.shield_outlined,
      iconColor: AppTheme.online,
      title: 'Stay Safe',
      subtitle:
          'Sensor history, trend analytics, and weather insights help you understand flood risk. Push notifications coming in Phase 2.',
      accent: AppTheme.online,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final accent = _pages[_currentPage].accent;

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

          // ── Accent glow (follows current page) ──
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: const Alignment(0, -0.4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 460,
                  height: 460,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Pages ──
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page, index);
            },
          ),

          // ── Step counter (top left) + Skip (top right) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20,
            right: 16,
            child: Row(
              children: [
                Text(
                  '${_currentPage + 1} / ${_pages.length}',
                  style: GoogleFonts.outfit(
                    color: AppTheme.subtext,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.cardSolid,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: const StadiumBorder(
                        side: BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.outfit(
                        color: AppTheme.subtext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom controls ──
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _currentPage
                            ? _pages[_currentPage].accent
                            : AppTheme.subtext.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          Color.lerp(accent, AppTheme.colDist, 0.45)!
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Get Started' : 'Next',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // ── Icon container with glow ──
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                colors: [
                  page.accent,
                  Color.lerp(page.accent, AppTheme.colDist, 0.45)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: page.accent.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 56),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                  begin: 0, end: -8, duration: 1800.ms, curve: Curves.easeInOut)
              .animate(key: ValueKey('icon_$index'))
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 48),

          // ── Title ──
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.2, duration: 400.ms),
          const SizedBox(height: 16),

          // ── Subtitle ──
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.subtext,
              fontSize: 15,
              height: 1.5,
            ),
          )
              .animate(key: ValueKey('sub_$index'))
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.15, duration: 400.ms),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color accent;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}
