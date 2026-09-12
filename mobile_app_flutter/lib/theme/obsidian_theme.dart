import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ObsidianTransitTheme {
  static const Color bgDeep = Color(0xFF050811);
  static const Color bgCard = Color(0xFF0B132B);
  static const Color bgCardHover = Color(0xFF14213D);
  static const Color cyanGlow = Color(0xFF00F0FF);
  static const Color emeraldGreen = Color(0xFF00FF9D);
  static const Color amberWarn = Color(0xFFFFCC00);
  static const Color crimsonDanger = Color(0xFFFF3B30);
  static const Color ksrtcRed = Color(0xFFD72638);
  static const Color ksrtcYellow = Color(0xFFFFD700);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      primaryColor: cyanGlow,
      colorScheme: const ColorScheme.dark(
        primary: cyanGlow,
        secondary: emeraldGreen,
        error: crimsonDanger,
        surface: bgCard,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          titleLarge: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x2E00F0FF), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xEB050811),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
