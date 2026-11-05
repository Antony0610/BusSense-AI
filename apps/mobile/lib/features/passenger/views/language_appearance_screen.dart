import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';

/// Screen managing commuter Language and Appearance preferences
class LanguageAppearanceScreen extends ConsumerWidget {
  const LanguageAppearanceScreen({super.key});

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Language & Appearance', style: AppTypography.titleLarge),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Language Section
            _buildSectionHeader('Language Selection'),
            _buildRadioOption(
              title: 'English (India)',
              subtitle: 'Primary regional transit language',
              isSelected: prefs.language == 'en',
              onTap: () => notifier.setLanguage('en'),
              trailing: const BusSenseStatusBadge(label: 'ACTIVE', tone: BadgeTone.success),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRadioOption(
              title: 'മലയാളം (Malayalam)',
              subtitle: 'പ്രാദേശിക ഭാഷാ സവിശേഷതകൾ',
              isSelected: prefs.language == 'ml',
              onTap: () => notifier.setLanguage('ml'),
              trailing: const BusSenseStatusBadge(label: 'PARTIAL / PREPARED', tone: BadgeTone.info),
            ),
            const SizedBox(height: 4),
            Text(
              'Malayalam localization framework is prepared. Full bilingual translations will roll out in subsequent phases.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, height: 1.3),
            ),

            // Appearance Section
            _buildSectionHeader('Appearance & Theme'),
            _buildRadioOption(
              title: 'System Default',
              subtitle: 'Match operating system appearance automatically',
              isSelected: prefs.themeMode == 'system',
              onTap: () => notifier.setThemeMode('system'),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRadioOption(
              title: 'Light Surface',
              subtitle: 'Google Stitch Ivory surface with Deep Forest Green tokens',
              isSelected: prefs.themeMode == 'light',
              onTap: () => notifier.setThemeMode('light'),
              trailing: const BusSenseStatusBadge(label: 'OPTIMIZED', tone: BadgeTone.success),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildRadioOption(
              title: 'Dark Mode',
              subtitle: 'High-contrast nocturnal transit palette',
              isSelected: prefs.themeMode == 'dark',
              onTap: () => notifier.setThemeMode('dark'),
              trailing: const BusSenseStatusBadge(label: 'PREPARED', tone: BadgeTone.info),
            ),
            const SizedBox(height: 4),
            Text(
              'Light surface is currently optimized for daytime commuter readability in Kerala sunlight conditions.',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
