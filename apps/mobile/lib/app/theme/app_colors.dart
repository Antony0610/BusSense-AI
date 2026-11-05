import 'package:flutter/material.dart';

/// BusSense AI - Stitch Approved Palette Tokens
class AppColors {
  // Primary Greens
  static const Color primary = Color(0xFF002620); // Deep Forest Green
  static const Color primaryContainer = Color(0xFF123C35); // Card container
  static const Color secondary = Color(0xFF006C49); // Kerala Green
  static const Color accent = Color(0xFF6CF8BB); // Electric Mint

  // Neutrals & Surfaces
  static const Color surface = Color(0xFFF3FBF7); // Light Surface
  static const Color surfaceVariant = Color(0xFFE0EBE6);
  static const Color darkSurface = Color(0xFF161D1B); // Near Black
  static const Color white = Color(0xFFFFFFFF);

  // Borders & Text
  static const Color textPrimary = Color(0xFF161D1B);
  static const Color textSecondary = Color(0xFF717976); // Muted
  static const Color textInverse = Color(0xFFF3FBF7);
  static const Color border = Color(0xFFC0C8C5);

  // Semantic Status Tones
  static const Color success = Color(0xFF006C49);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFBA1A1A);

  // Crowd Density Standard Colors
  static const Color crowdLow = Color(0xFF006C49); // < 50%
  static const Color crowdModerate = Color(0xFFD97706); // 50-80%
  static const Color crowdHigh = Color(0xFFBA1A1A); // > 80%
}
