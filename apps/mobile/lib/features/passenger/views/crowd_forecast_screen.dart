import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/widgets/bussense_error_state.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';

/// 4-Horizon Crowd Forecast Screen for commuters
class CrowdForecastScreen extends ConsumerWidget {
  final String busNumber;

  const CrowdForecastScreen({super.key, required this.busNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(busPredictionProvider(busNumber));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crowd Forecast', style: AppTypography.titleLarge),
            Text('Bus $busNumber • 4-Horizon Trajectory', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BusSenseStatusBadge(label: 'PREDICTION', tone: BadgeTone.warning),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: predictionAsync.when(
          data: (pred) => SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Disclaimer Banner
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Estimated cabin occupancy at 4 forward horizons based on simulated transit corridor models.',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Corridor Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Forecast Trajectory', style: AppTypography.titleLarge),
                    Text(
                      'Confidence: ${(pred.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4 Horizons: NOW, +15 MIN, +30 MIN, +60 MIN
                _buildHorizonCard(
                  timeLabel: 'NOW',
                  minutesFromNow: 0,
                  occupancyPct: pred.nowOccupancyPct,
                  crowdLevel: pred.nowCrowdLevel,
                  confidence: pred.confidenceScore,
                  isLive: true,
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildHorizonCard(
                  timeLabel: '+15 MIN',
                  minutesFromNow: 15,
                  occupancyPct: pred.plus15mOccupancyPct,
                  crowdLevel: pred.plus15mCrowdLevel,
                  confidence: pred.confidenceScore,
                  isLive: false,
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildHorizonCard(
                  timeLabel: '+30 MIN',
                  minutesFromNow: 30,
                  occupancyPct: pred.plus30mOccupancyPct,
                  crowdLevel: pred.plus30mCrowdLevel,
                  confidence: pred.confidenceScore,
                  isLive: false,
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildHorizonCard(
                  timeLabel: '+60 MIN',
                  minutesFromNow: 60,
                  occupancyPct: pred.plus60mOccupancyPct,
                  crowdLevel: pred.plus60mCrowdLevel,
                  confidence: 0.81,
                  isLive: false,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Honesty & Prototype Disclosure Card
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                          Text('DATA DISCLOSURE & PROTOTYPE NOTICE', style: AppTypography.labelSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Prediction values are calculated using simulated machine learning models (${pred.modelVersion}). They do not represent physical hardware longitudinal Kerala transport datasets.',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const BusSenseLoading(message: 'Generating 4-horizon demand trajectory...'),
          error: (err, _) => BusSenseErrorState(
            title: 'Forecast Unavailable',
            message: err.toString(),
            onRetry: () => ref.refresh(busPredictionProvider(busNumber)),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizonCard({
    required String timeLabel,
    required int minutesFromNow,
    required double occupancyPct,
    required CrowdLevel crowdLevel,
    required double confidence,
    required bool isLive,
  }) {
    final crowdTone = switch (crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    final crowdColor = switch (crowdLevel) {
      CrowdLevel.low => AppColors.crowdLow,
      CrowdLevel.moderate => AppColors.crowdModerate,
      CrowdLevel.crowded => AppColors.crowdHigh,
    };

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isLive ? AppColors.secondary : AppColors.border.withValues(alpha: 0.35),
          width: isLive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: isLive ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      timeLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: isLive ? AppColors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    isLive ? 'Current Telemetry' : '+$minutesFromNow min estimate',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
              BusSenseStatusBadge(
                label: isLive ? 'LIVE DATA' : 'PREDICTION',
                tone: isLive ? BadgeTone.success : BadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Occupancy & Crowd Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${occupancyPct.toStringAsFixed(1)}%',
                    style: AppTypography.tabularNumeral.copyWith(fontSize: 22, color: crowdColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Occupancy', style: AppTypography.bodyMedium),
                ],
              ),
              BusSenseStatusBadge(label: crowdLevel.value, tone: crowdTone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Horizon Progress Bar
          ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: LinearProgressIndicator(
              value: (occupancyPct / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(crowdColor),
            ),
          ),
        ],
      ),
    );
  }
}
