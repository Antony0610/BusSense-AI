import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';

/// Screen displaying operational cabin occupancy, seated/standing metrics, and crowd thresholds
class ConductorOccupancyScreen extends ConsumerWidget {
  final String busNumber;

  const ConductorOccupancyScreen({super.key, this.busNumber = '205'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupancyAsync = ref.watch(conductorOccupancyProvider(busNumber));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Cabin Occupancy', style: AppTypography.titleLarge),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: occupancyAsync.when(
          loading: () => const BusSenseLoading(message: 'Querying onboard cabin sensors...'),
          error: (err, st) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                const SizedBox(height: AppSpacing.sm),
                Text('Failed to read occupancy telemetry', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.md),
                BusSenseButton(
                  label: 'Retry',
                  variant: ButtonVariant.outline,
                  onPressed: () => ref.refresh(conductorOccupancyProvider(busNumber)),
                ),
              ],
            ),
          ),
          data: (crowd) {
            final occupancyPct = crowd?.occupancyPercentage ?? 41.8;
            final seated = crowd?.seatedPassengers ?? 23;
            final standing = crowd?.standingPassengers ?? 0;
            final freeSeats = (35 - seated) > 0 ? (35 - seated) : 0;

            final crowdTone = occupancyPct < 50.0
                ? BadgeTone.success
                : (occupancyPct <= 80.0 ? BadgeTone.warning : BadgeTone.error);
            final crowdLabel = occupancyPct < 50.0
                ? 'LOW'
                : (occupancyPct <= 80.0 ? 'MODERATE' : 'CROWDED');

            return ListView(
              padding: AppSpacing.paddingScreen,
              children: [
                // Header vehicle badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('BUS $busNumber CABIN DENSITY', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    BusSenseStatusBadge(label: crowdLabel, tone: crowdTone),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Primary Large Percentage Display
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${occupancyPct.toStringAsFixed(1)}%',
                        style: AppTypography.displayMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: crowdTone == BadgeTone.success
                              ? AppColors.secondary
                              : (crowdTone == BadgeTone.warning ? AppColors.warning : AppColors.error),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Estimated Cabin Density',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Linear Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (occupancyPct / 100.0).clamp(0.0, 1.0),
                          minHeight: 14,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            crowdTone == BadgeTone.success
                                ? AppColors.secondary
                                : (crowdTone == BadgeTone.warning ? AppColors.warning : AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Seat Breakdown Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.airline_seat_recline_normal_rounded,
                        title: 'Seated',
                        value: '$seated / 35',
                        subtitle: '$freeSeats seats free',
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.directions_walk_rounded,
                        title: 'Standing',
                        value: '$standing / 20',
                        subtitle: 'Capacity comfortable',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Operational Crowd Thresholds Card
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operational Thresholds', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),
                      _buildThresholdRow('LOW (< 50%)', 'Ample seating available. Boarding rapid.', AppColors.secondary),
                      const Divider(height: AppSpacing.md),
                      _buildThresholdRow('MODERATE (50–80%)', 'Seating limited. Aisle movement active.', AppColors.warning),
                      const Divider(height: AppSpacing.md),
                      _buildThresholdRow('CROWDED (> 80%)', 'Standing only. Prioritize exit doors.', AppColors.error),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Truth Disclosure Card
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: AppColors.secondary, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BusSenseStatusBadge(label: 'SIMULATED DATA • ZERO BIOMETRICS', tone: BadgeTone.info),
                            const SizedBox(height: 4),
                            Text(
                              'Computer vision pipeline performs body silhouette counting only. Facial biometrics are strictly disabled.',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Refresh Telemetry Button
                BusSenseButton(
                  label: 'Refresh Occupancy Telemetry',
                  variant: ButtonVariant.outline,
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.refresh(conductorOccupancyProvider(busNumber)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildThresholdRow(String title, String desc, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              Text(desc, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
