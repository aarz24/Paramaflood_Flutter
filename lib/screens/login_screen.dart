import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = AuthService();

    try {
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        // Successful campus login -> Navigate to Main Dashboard
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } on AuthDomainException catch (e) {
      if (mounted) {
        _showAccessDeniedDialog(e.email ?? '');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAccessDeniedDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.offline.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                color: AppTheme.offline,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Akses Ditolak',
                style: GoogleFonts.outfit(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi ParamaFlood Monitor dibatasi hanya untuk sivitas akademika Universitas Paramadina.',
              style: GoogleFonts.outfit(
                color: AppTheme.text,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akun yang Anda pilih:',
                    style: GoogleFonts.outfit(
                      color: AppTheme.subtext,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email.isNotEmpty ? email : 'Bukan akun kampus',
                    style: GoogleFonts.outfit(
                      color: AppTheme.offline,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Gunakan akun Google dengan domain:',
              style: GoogleFonts.outfit(
                color: AppTheme.subtext,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const _DomainBadge(
              domain: '@students.paramadina.ac.id',
              label: 'Mahasiswa',
            ),
            const SizedBox(height: 4),
            const _DomainBadge(
              domain: '@paramadina.ac.id',
              label: 'Dosen / Staf',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Mengerti',
              style: GoogleFonts.outfit(
                color: AppTheme.heroAcc,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Background Gradient ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.bg,
                    AppTheme.bgAlt,
                    AppTheme.colDist.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Atmospheric Pulsing Glow ──
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) {
              return Positioned(
                top: -80 + (_pulseCtrl.value * 20),
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.heroAcc.withValues(alpha: 0.18),
                        AppTheme.heroAcc.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Campus Pill Badge ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: AppTheme.heroAcc.withValues(alpha: 0.3), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.heroAcc.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            color: AppTheme.heroAcc,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'UNIVERSITAS PARAMADINA',
                            style: GoogleFonts.outfit(
                              color: AppTheme.heroAcc,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),

                    const SizedBox(height: 28),

                    // ── App Emblem Icon ──
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: AppTheme.cardBorder, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.colDist.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/images/Logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.water_damage_rounded,
                            size: 48,
                            color: AppTheme.heroAcc,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 24),

                    // ── Titles ──
                    Text(
                      'ParamaFlood',
                      style: GoogleFonts.outfit(
                        color: AppTheme.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 6),

                    Text(
                      'Sistem Peringatan Dini Banjir Berbasis IoT & AI\nKampus Universitas Paramadina',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: AppTheme.subtext,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 36),

                    // ── Domain Restriction Notice Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.heroAcc.withValues(alpha: 0.25), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.heroAcc.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppTheme.heroAcc.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: AppTheme.heroAcc,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Akses Khusus Sivitas Kampus',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Untuk keamanan data sensor banjir, sistem hanya dapat diakses melalui akun Google Gmail resmi kampus:',
                            style: GoogleFonts.outfit(
                              color: AppTheme.subtext,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            children: [
                              Expanded(
                                child: _SmallDomainTag(
                                  icon: Icons.person_rounded,
                                  domain: '@students.paramadina.ac.id',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Expanded(
                                child: _SmallDomainTag(
                                  icon: Icons.badge_rounded,
                                  domain: '@paramadina.ac.id',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

                    // ── Error Message Banner (if any) ──
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.offline.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.offline.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.offline,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.outfit(
                                  color: AppTheme.offline,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(duration: 400.ms),
                    ],

                    // ── Google Sign-In Action Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.text,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppTheme.cardBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.heroAcc,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Memverifikasi Akun...',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google Custom 'G' Logo icon
                                  _GoogleLogoIcon(),
                                  const SizedBox(width: 14),
                                  Text(
                                    'Masuk dengan Akun Paramadina',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),

                    const SizedBox(height: 24),

                    // ── Footer ──
                    Text(
                      'ParamaFlood © 2026 Universitas Paramadina\nKarya Akhir IoT Flood Early Warning System',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: AppTheme.subtext.withValues(alpha: 0.7),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainBadge extends StatelessWidget {
  final String domain;
  final String label;
  const _DomainBadge({required this.domain, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.heroAcc.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.online, size: 14),
          const SizedBox(width: 6),
          Text(
            domain,
            style: GoogleFonts.outfit(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($label)',
            style: GoogleFonts.outfit(
              color: AppTheme.subtext,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallDomainTag extends StatelessWidget {
  final IconData icon;
  final String domain;
  const _SmallDomainTag({required this.icon, required this.domain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.heroAcc),
          const SizedBox(width: 8),
          Text(
            domain,
            style: GoogleFonts.outfit(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        painter: _GoogleGPainter(),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Precise Google G Brand Emblem
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;

    // Draw stylized multi-color G
    // Fallback crisp 4-color rendering
    canvas.drawCircle(center, radius, bluePaint);
    final inner = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, inner);

    // Inner right cut
    final cut = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(center.dx, center.dy - radius * 0.35, radius, radius * 0.7), cut);

    // Blue horizontal bar
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 2, center.dy - 3, radius + 2, 6),
        const Radius.circular(3),
      ),
      bar,
    );

    // Top red arc
    final arcPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      3.14 * 1.25,
      3.14 * 0.5,
      false,
      arcPaint,
    );

    // Bottom green arc
    final greenArc = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      3.14 * 0.25,
      3.14 * 0.5,
      false,
      greenArc,
    );

    // Left yellow arc
    final yellowArc = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      3.14 * 0.75,
      3.14 * 0.5,
      false,
      yellowArc,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
