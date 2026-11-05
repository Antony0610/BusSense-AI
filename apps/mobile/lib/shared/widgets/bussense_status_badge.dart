import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../design/app_spacing.dart';

enum BadgeTone { success, warning, error, neutral, accent, info }

/// Stitch Status Badge Pill
class BusSenseStatusBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;

  const BusSenseStatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (tone) {
      case BadgeTone.success:
        bg = AppColors.secondary.withValues(alpha: 0.12);
        fg = AppColors.secondary;
        break;
      case BadgeTone.warning:
        bg = AppColors.warning.withValues(alpha: 0.14);
        fg = const Color(0xFFB45309);
        break;
      case BadgeTone.error:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
      case BadgeTone.accent:
        bg = AppColors.accent;
        fg = const Color(0xFF005236);
        break;
      case BadgeTone.info:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      case BadgeTone.neutral:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
