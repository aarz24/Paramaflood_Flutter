import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Clean White & Water Blue Palette ──────────────────────────
  static const Color bg = Color(0xFFF8FBFF);          // Soft Ice White
  static const Color bgAlt = Color(0xFFEFF6FF);       // Pale Water Blue Tint
  static const Color card = Color(0x1A3B82F6);         // Glass Water Card
  static const Color cardSolid = Color(0xFFFFFFFF);    // Pure White Card
  static const Color cardBorder = Color(0xFFDBE8F4);   // Soft Blue-Grey Border

  static const Color text = Color(0xFF0F172A);         // Deep Slate Text
  static const Color subtext = Color(0xFF64748B);      // Cool Muted Slate

  // ── Feature & Telemetry Accents ──────────────────────────────
  static const Color heroAcc = Color(0xFF0EA5E9);      // Water Sky Blue
  static const Color colTemp = Color(0xFFE67E22);      // Warm Terracotta
  static const Color colHum = Color(0xFF0284C7);       // Deep Water Blue
  static const Color colWind = Color(0xFF64748B);      // Wind Slate
  static const Color colPres = Color(0xFF7C3AED);      // Atmospheric Violet
  static const Color colLight = Color(0xFFD97706);     // Sunlight Amber
  static const Color colRain = Color(0xFF2563EB);      // Rain Indigo Blue
  static const Color colDist = Color(0xFF0369A1);      // Flood Steel Blue
  static const Color colBatt = Color(0xFF059669);      // Eco Emerald

  static const Color online = Color(0xFF059669);       // Emerald Green
  static const Color warning = Color(0xFFD97706);      // Amber Alert
  static const Color offline = Color(0xFFDC2626);      // Danger Red
  static const Color internet = Color(0xFF7C3AED);     // Sync Purple

  static const Color divider = Color(0x1A94A3B8);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    cardColor: cardSolid,
    colorScheme: const ColorScheme.light(
      primary: heroAcc,
      secondary: colHum,
      surface: cardSolid,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        color: text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardSolid,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.outfit(
        color: text,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.outfit(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.outfit(
        color: heroAcc,
        fontSize: 14,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.outfit(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.outfit(
        color: subtext,
        fontSize: 12,
      ),
      labelSmall: GoogleFonts.outfit(
        color: subtext,
        fontSize: 10,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: divider,
  );
}
