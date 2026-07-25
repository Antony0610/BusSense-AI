import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color bgDark = Color(0xFF0B1720);
  static const Color surfaceDark = Color(0xFF12232E);
  static const Color surface2Dark = Color(0xFF1A2F3D);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  static const Color greenCrowd = Color(0xFF10B981);
  static const Color yellowCrowd = Color(0xFFF59E0B);
  static const Color redCrowd = Color(0xFFF43F5E);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryTeal,
      secondary: accentTeal,
      surface: surfaceDark,
      background: bgDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: textPrimaryDark,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textPrimaryDark),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: textPrimaryDark),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimaryDark),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimaryDark),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondaryDark),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: textMutedDark),
    ),
    cardTheme: CardTheme(
      color: surfaceDark,
      elevation: 4,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF1F7F5),
    colorScheme: const ColorScheme.light(
      primary: primaryTeal,
      secondary: accentTeal,
      surface: Colors.white,
      background: Color(0xFFF1F7F5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Color(0xFF0F172A),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
