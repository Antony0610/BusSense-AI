import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';

/// Screen managing commuter notification preferences across journey, crowd, and service categories
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

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

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: enabled ? AppColors.secondary : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppColors.secondary,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);
    final masterOn = prefs.masterNotifications;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Notification Preferences', style: AppTypography.titleLarge),
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
            // Master Switch
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.roundedMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allow Notifications',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Master control for all BusSense alerts',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: masterOn,
                    onChanged: (val) => notifier.toggleMaster(val),
                    activeTrackColor: AppColors.accent,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            // Journey Section
            _buildSectionHeader('Journey & ETA Alerts'),
            _buildSwitchRow(
              title: 'Bus Arrival Alerts',
              subtitle: 'Notifications when your bus is within 5 minutes of your stop',
              icon: Icons.departure_board_rounded,
              value: prefs.busArrival && masterOn,
              enabled: masterOn,
              onChanged: (val) => notifier.updatePreferences(prefs.copyWith(busArrival: val)),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildSwitchRow(
              title: 'Journey & Delay Updates',
              subtitle: 'Corridor traffic delays and stop advancement notices',
              icon: Icons.alt_route_rounded,
              value: prefs.journeyUpdates && masterOn,
              enabled: masterOn,
              onChanged: (val) => notifier.updatePreferences(prefs.copyWith(journeyUpdates: val)),
            ),

            // Crowd Section
            _buildSectionHeader('Crowd Intelligence'),
            _buildSwitchRow(
              title: 'Crowd Pressure Warnings',
              subtitle: 'Alerts when a monitored bus exceeds 75% cabin occupancy',
              icon: Icons.people_outline_rounded,
              value: prefs.crowdAlerts && masterOn,
              enabled: masterOn,
              onChanged: (val) => notifier.updatePreferences(prefs.copyWith(crowdAlerts: val)),
            ),

            // Service & Route Section
            _buildSectionHeader('Service & Network Advisories'),
            _buildSwitchRow(
              title: 'Route & Corridor Advisories',
              subtitle: 'Maintenance, detour, and priority lane notices in Greater Kochi',
              icon: Icons.warning_amber_rounded,
              value: prefs.serviceAlerts && masterOn,
              enabled: masterOn,
              onChanged: (val) => notifier.updatePreferences(prefs.copyWith(serviceAlerts: val)),
            ),

            // Tickets Section
            _buildSectionHeader('Ticketing & QR Pass Updates'),
            _buildSwitchRow(
              title: 'Booking & Pass Expiration',
              subtitle: 'Booking confirmations and validity window expiration alerts',
              icon: Icons.confirmation_number_outlined,
              value: prefs.ticketUpdates && masterOn,
              enabled: masterOn,
              onChanged: (val) => notifier.updatePreferences(prefs.copyWith(ticketUpdates: val)),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Truth & Deferral Label
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BusSenseStatusBadge(
                    label: 'PREFERENCE MODEL • PUSH DELIVERY DEFERRED',
                    tone: BadgeTone.info,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Push notification infrastructure is deferred per Phase H5 roadmap. Category selections are persisted to your commuter profile for future activation.',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
