import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'crowd_forecast_screen.dart';
import 'smart_recommendation_screen.dart';
import 'ticket_booking_screen.dart';

/// Bus Details Screen for any selected vehicle in the fleet
class BusDetailsScreen extends ConsumerWidget {
  final BusModel bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(activeAlertsProvider);
    final predictionAsync = ref.watch(busPredictionProvider(bus.busNumber));

    final crowdTone = switch (bus.crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    final crowdColor = switch (bus.crowdLevel) {
      CrowdLevel.low => AppColors.crowdLow,
      CrowdLevel.moderate => AppColors.crowdModerate,
      CrowdLevel.crowded => AppColors.crowdHigh,
    };

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bus ${bus.busNumber}', style: AppTypography.titleLarge),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BusSenseStatusBadge(label: 'SIMULATED DATA', tone: BadgeTone.neutral),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bus Profile Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Text(
                            bus.busNumber,
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bus.routeName, style: AppTypography.titleMedium),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${bus.operatorType} • Reg: ${bus.registrationNumber}',
                                style: AppTypography.bodyMedium,
                              ),
                              if (bus.isAc) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Row(
                                  children: [
                                    const Icon(Icons.ac_unit_rounded, size: 14, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text('Air Conditioned Service', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // Stops & ETA Progress Grid
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Location', style: AppTypography.labelSmall),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                bus.currentStop.isNotEmpty ? bus.currentStop : 'In Corridor Transit',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.border.withValues(alpha: 0.4)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Next Approaching Stop', style: AppTypography.labelSmall),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                bus.nextStop.isNotEmpty ? bus.nextStop : 'Terminal',
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ETA Highlight
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Next Stop Arrival', style: AppTypography.labelSmall),
                              Text('Based on corridor physics', style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${bus.etaNextStopMins}',
                                style: AppTypography.tabularNumeral.copyWith(
                                  fontSize: 32,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'MIN',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Cabin Occupancy & Crowd Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cabin Occupancy', style: AppTypography.titleLarge),
                        BusSenseStatusBadge(label: bus.crowdLevel.value, tone: crowdTone),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Progress bar
                    ClipRRect(
                      borderRadius: AppSpacing.roundedFull,
                      child: LinearProgressIndicator(
                        value: (bus.occupancyPct / 100.0).clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(crowdColor),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${bus.occupancyPct.toStringAsFixed(1)}% Capacity',
                          style: AppTypography.titleMedium.copyWith(color: crowdColor),
                        ),
                        Text(
                          '${bus.passengerCount} / ${bus.capacity} Passengers',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Privacy Standard: Body/Head bounding boxes only. No facial biometrics or passenger tracking.',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Alert Banner if applicable
              alertsAsync.when(
                data: (alerts) {
                  final busAlerts = alerts.where((a) => a.affectedRoute.contains(bus.busNumber) || a.affectedRoute.contains(bus.routeNumber)).toList();
                  if (busAlerts.isEmpty) return const SizedBox.shrink();
                  final alert = busAlerts.first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Service Alert: ${alert.title}', style: AppTypography.labelLarge),
                                Text(alert.message, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Demand Prediction Preview Summary
              predictionAsync.when(
                data: (pred) => Container(
                  padding: AppSpacing.paddingMd,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: AppColors.secondary, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('4-Horizon Demand Forecast', style: AppTypography.labelLarge),
                            Text(
                              '+15m: ${pred.plus15mOccupancyPct.toStringAsFixed(0)}% • +30m: ${pred.plus30mOccupancyPct.toStringAsFixed(0)}% • +60m: ${pred.plus60mOccupancyPct.toStringAsFixed(0)}%',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const BusSenseStatusBadge(label: 'PREDICTION', tone: BadgeTone.neutral),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Booking Action (Primary)
              BusSenseButton(
                label: 'Book Digital Boarding Pass',
                icon: Icons.confirmation_number_rounded,
                variant: ButtonVariant.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TicketBookingScreen(bus: bus),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Navigation Actions to Forecast & Recommendations
              BusSenseButton(
                label: 'View Crowd Forecast (4 Horizons)',
                icon: Icons.trending_up_rounded,
                variant: ButtonVariant.outline,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrowdForecastScreen(busNumber: bus.busNumber),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              BusSenseButton(
                label: 'Smart Journey Recommendations',
                icon: Icons.auto_awesome_outlined,
                variant: ButtonVariant.outline,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmartRecommendationScreen(
                        busNumber: bus.busNumber,
                        routeName: bus.routeName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
