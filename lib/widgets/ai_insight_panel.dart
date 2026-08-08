import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/app_theme.dart';

/// 🧠 Panel Analisis AI Gemini — Fitur 1 & 2 (analisis cuaca + risiko banjir)
/// + Fitur 4 (laporan harian) + Fitur 5 (banner notifikasi cerdas).
class AiInsightPanel extends StatelessWidget {
  const AiInsightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.cardSolid,
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.heroAcc.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon + title + risk badge + refresh ──────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.heroAcc.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.heroAcc, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANALISIS KECERDASAN AI',
                      style: GoogleFonts.outfit(
                        color: AppTheme.heroAcc,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Ringkasan Cuaca & Prediksi Banjir',
                      style: GoogleFonts.outfit(
                        color: AppTheme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _RiskBadge(level: state.floodRiskLevel),
              IconButton(
                onPressed:
                    state.isAiLoading ? null : () => state.refreshAiAnalysis(),
                icon: state.isAiLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.heroAcc,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded,
                        color: AppTheme.subtext, size: 20),
                tooltip: 'Perbarui Analisis AI',
              ),
            ],
          ),

          // ── Smart Alert banner (Fitur 5) ─────────────────────────
          if (state.smartAlert.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.offline.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.offline.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: AppTheme.offline, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.smartAlert,
                      style: GoogleFonts.outfit(
                        color: AppTheme.text,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => state.clearSmartAlert(),
                    child: const Icon(Icons.close_rounded,
                        color: AppTheme.subtext, size: 16),
                  ),
                ],
              ),
            ).animate().fadeIn().shake(hz: 3, duration: 500.ms),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 14),

          // ── Content ──────────────────────────────────────────────
          if (state.isAiLoading && state.aiAnalysis.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.heroAcc),
                    const SizedBox(height: 12),
                    Text(
                      'AI sedang menganalisis data sensor...',
                      style: GoogleFonts.outfit(
                        color: AppTheme.subtext,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (state.aiAnalysis.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (!state.isAiConfigured) ...[
                      Text(
                        '🔑 API key Gemini belum diisi — buka lib/config/api_keys.dart',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: AppTheme.subtext,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => state.refreshAiAnalysis(),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Jalankan Analisis AI Pertama'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.heroAcc,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SelectableText(
              state.aiAnalysis,
              style: GoogleFonts.outfit(
                color: AppTheme.text.withOpacity(0.92),
                fontSize: 13,
                height: 1.55,
              ),
            ).animate().fadeIn(duration: 300.ms),

          // ── Cooldown / error info ────────────────────────────────
          if (state.aiError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.colLight, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.aiError,
                    style: GoogleFonts.outfit(
                      color: AppTheme.colLight,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Daily report (Fitur 4) ───────────────────────────────
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isReportLoading
                      ? null
                      : () {
                          state.generateDailyReport();
                          _showDailyReportSheet(context);
                        },
                  icon: state.isReportLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.heroAcc,
                          ),
                        )
                      : const Icon(Icons.summarize_outlined, size: 16),
                  label: const Text('Laporan Harian AI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.heroAcc,
                    side: BorderSide(
                        color: AppTheme.heroAcc.withOpacity(0.35)),
                    textStyle: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDailyReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DailyReportSheet(),
    );
  }
}

/// Badge tingkat risiko banjir (hijau/kuning/oranye/merah).
class _RiskBadge extends StatelessWidget {
  final String level;
  const _RiskBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    IconData icon;

    switch (level.toUpperCase()) {
      case 'KRITIS':
        bg = const Color(0xFFEF4444);
        label = 'KRITIS';
        icon = Icons.warning_amber_rounded;
        break;
      case 'TINGGI':
        bg = const Color(0xFFF97316);
        label = 'TINGGI';
        icon = Icons.error_outline_rounded;
        break;
      case 'SEDANG':
        bg = const Color(0xFFF59E0B);
        label = 'SEDANG';
        icon = Icons.info_outline_rounded;
        break;
      case 'RENDAH':
        bg = const Color(0xFF10B981);
        label = 'AMAN';
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        bg = AppTheme.subtext;
        label = 'N/A';
        icon = Icons.hourglass_empty_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bg, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: bg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet laporan harian AI (Fitur 4).
class _DailyReportSheet extends StatelessWidget {
  const _DailyReportSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardSolid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppTheme.heroAcc, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan Harian ParamaFlood',
                  style: GoogleFonts.outfit(
                    color: AppTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.subtext),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 8),
          Flexible(
            child: state.isReportLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child:
                          CircularProgressIndicator(color: AppTheme.heroAcc),
                    ),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      state.dailyReport.isEmpty
                          ? 'Menyiapkan laporan...'
                          : state.dailyReport,
                      style: GoogleFonts.outfit(
                        color: AppTheme.text.withOpacity(0.92),
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
