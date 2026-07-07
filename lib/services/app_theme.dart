import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF050814);
  static const Color bgAlt = Color(0xFF0B1120);
  static const Color card = Color(0x33111A33);
  static const Color cardSolid = Color(0xFF111A30);
  static const Color text = Color(0xFFF4F7FB);
  static const Color subtext = Color(0xFF93A4BF);

  static const Color colHum = Color(0xFF35B8FF);
  static const Color colWind = Color(0xFF38D996);
  static const Color colPres = Color(0xFFA78BFA);
  static const Color heroAcc = Color(0xFF66D6FF);
  static const Color colTemp = Color(0xFFFF7A59);
  static const Color colLight = Color(0xFFFBBF24);
  static const Color colRain = Color(0xFF6C7CFF);
  static const Color colDist = Color(0xFF2DD4BF);
  static const Color colBatt = Color(0xFF4ADE80);

  static const Color online = Color(0xFF32D583);
  static const Color offline = Color(0xFFF97066);
  static const Color internet = Color(0xFFA78BFA);

  static const Color divider = Color(0x26D8E2F0);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    cardColor: cardSolid,
    colorScheme: const ColorScheme.dark(
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
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.outfit(
        color: text,
        fontSize: 50,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      displayMedium: GoogleFonts.outfit(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.outfit(
        color: heroAcc,
        fontSize: 14,
        letterSpacing: 2,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.outfit(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.outfit(
        color: subtext,
        fontSize: 12,
      ),
      labelSmall: GoogleFonts.outfit(
        color: subtext,
        fontSize: 9,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerColor: divider,
  );
}
