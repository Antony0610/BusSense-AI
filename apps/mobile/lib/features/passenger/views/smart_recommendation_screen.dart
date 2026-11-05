import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/recommendation_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_error_state.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'bus_details_screen.dart';

/// Smart Recommendation Screen presenting explainable backend transit recommendations
class SmartRecommendationScreen extends ConsumerWidget {
  final String? busNumber;
  final String? routeName;

  const SmartRecommendationScreen({
    super.key,
    this.busNumber,
    this.routeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(journeyPlanProvider);

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
            Text('Smart Recommendation', style: AppTypography.titleLarge),
            Text('Explainable Transit Optimization', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BusSenseStatusBadge(label: 'RECOMMENDATION', tone: BadgeTone.accent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: planAsync.when(
          data: (plan) => SingleChildScrollView(
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Corridor Header Summary
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route_outlined, color: AppColors.secondary, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Corridor Route', style: AppTypography.labelSmall),
                            Text('${plan.originStop} ➔ ${plan.destinationStop}', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // "Recommended For You" Hero Card
                _buildHeroRecommendation(context, plan.recommendedBus),
                const SizedBox(height: AppSpacing.lg),

                // Explanation Block
                if (plan.explanation.isNotEmpty) ...[
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined, size: 18, color: AppColors.secondary),
                            const SizedBox(width: AppSpacing.xs),
                            Text('RECOMMENDATION RATIONALE', style: AppTypography.labelSmall),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(plan.explanation, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Alternatives Comparison
                if (plan.alternativeBuses.isNotEmpty) ...[
                  Text('Alternative Options Evaluated', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  ...plan.alternativeBuses.map((alt) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildAlternativeRow(context, alt),
                      )),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Honest Disclaimer
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Recommendations are generated by the backend recommendation engine combining arrival times, occupancy deltas, and priority lane heuristics. Telemetry is simulated.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          loading: () => const BusSenseLoading(message: 'Scoring corridor buses for lowest crowd & fastest arrival...'),
          error: (err, _) => BusSenseErrorState(
            title: 'Unable to Generate Recommendation',
            message: err.toString(),
            onRetry: () => ref.refresh(journeyPlanProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroRecommendation(BuildContext context, BusRecommendationItem rec) {
    final crowdTone = switch (rec.crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.secondary, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BusSenseStatusBadge(label: 'RECOMMENDED FOR YOU', tone: BadgeTone.accent),
              Text(
                'Score: ${rec.journeyScore.toStringAsFixed(1)}',
                style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Bus Number & Route
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  rec.busNumber,
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.routeName, style: AppTypography.titleMedium),
                    Text('${rec.operatorType} • Fare: ₹${rec.fareInr.toStringAsFixed(0)}', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rec.etaMins} min',
                    style: AppTypography.tabularNumeral.copyWith(fontSize: 22, color: AppColors.secondary),
                  ),
                  Text('Arrival ETA', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Crowd & Occupancy pill
          Container(
            padding: AppSpacing.paddingSm,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                BusSenseStatusBadge(label: rec.crowdLevel.value, tone: crowdTone),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${rec.occupancyPct.toStringAsFixed(0)}% Occupancy',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Why this bus? Section
          Text('Why this bus?', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),

          if (rec.crowdSavingVsAlternativePct != null) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${rec.crowdSavingVsAlternativePct!.toStringAsFixed(0)}% lower crowding compared to alternative',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],

          if (rec.timeSavingMins != null) ...[
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Saves ${rec.timeSavingMins} minutes via priority corridor',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
          ],

          Text(rec.whyRecommended, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.md),

          BusSenseButton(
            label: 'Inspect Bus ${rec.busNumber}',
            icon: Icons.directions_bus_rounded,
            variant: ButtonVariant.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusDetailsScreen(
                    bus: BusModel(
                      busId: 'rec-${rec.busNumber}',
                      busNumber: rec.busNumber,
                      registrationNumber: 'KL-15-A-2051',
                      operatorType: rec.operatorType,
                      routeNumber: rec.routeNumber,
                      routeName: rec.routeName,
                      capacity: 55,
                      passengerCount: (55 * (rec.occupancyPct / 100.0)).round(),
                      occupancyPct: rec.occupancyPct,
                      crowdLevel: rec.crowdLevel,
                      speedKmh: 42.0,
                      headingDeg: 195.0,
                      latitude: 9.9816,
                      longitude: 76.3031,
                      currentStop: 'Kaloor Metro Stand',
                      nextStop: 'En route Vyttila',
                      etaNextStopMins: rec.etaMins,
                      dataOrigin: rec.dataOrigin,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeRow(BuildContext context, BusRecommendationItem alt) {
    final crowdTone = switch (alt.crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  alt.busNumber,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alt.routeName, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                    Text('ETA ${alt.etaMins}m • ₹${alt.fareInr.toStringAsFixed(0)}', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              BusSenseStatusBadge(label: alt.crowdLevel.value, tone: crowdTone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(alt.whyRecommended, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
