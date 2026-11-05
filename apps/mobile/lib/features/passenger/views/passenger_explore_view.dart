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
import 'ticket_booking_screen.dart';

/// Passenger Explore & Route Planning Screen
class PassengerExploreView extends ConsumerStatefulWidget {
  final String? initialDestination;
  const PassengerExploreView({super.key, this.initialDestination});

  @override
  ConsumerState<PassengerExploreView> createState() => _PassengerExploreViewState();
}

class _PassengerExploreViewState extends ConsumerState<PassengerExploreView> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;

  @override
  void initState() {
    super.initState();
    final query = ref.read(journeyQueryProvider);
    final targetDest = widget.initialDestination ?? query.destination;
    _originController = TextEditingController(text: query.origin);
    _destinationController = TextEditingController(text: targetDest);
    if (widget.initialDestination != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(journeyQueryProvider.notifier).state = query.copyWith(destination: widget.initialDestination!);
      });
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    final origin = _originController.text.trim();
    final dest = _destinationController.text.trim();
    if (origin.isEmpty || dest.isEmpty) return;

    ref.read(journeyQueryProvider.notifier).state = JourneyQuery(
      origin: origin,
      destination: dest,
    );
  }

  void _swapStops() {
    final temp = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = temp;
    _triggerSearch();
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(journeyPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingScreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Journey Query Input Card
                    _buildSearchCard(context),
                    const SizedBox(height: AppSpacing.md),

                    // Quick Corridor Presets
                    _buildCorridorPresets(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Plan Results
            planAsync.when(
              data: (plan) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Corridor Overview Card
                    _buildCorridorSummary(context, plan),
                    const SizedBox(height: AppSpacing.lg),

                    // Recommended Bus Hero
                    _buildRecommendedHero(context, plan.recommendedBus),
                    const SizedBox(height: AppSpacing.xl),

                    // Alternative Options
                    if (plan.alternativeBuses.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Corridor Alternatives', style: AppTypography.titleLarge),
                          const BusSenseStatusBadge(label: 'SIMULATED DATA', tone: BadgeTone.neutral),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...plan.alternativeBuses.map((alt) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildAlternativeCard(context, alt),
                          )),
                    ],
                  ]),
                ),
              ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: BusSenseLoading(message: 'Evaluating live route crowding & schedules...'),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: BusSenseErrorState(
                  title: 'Journey Search Failed',
                  message: err.toString(),
                  onRetry: () => ref.refresh(journeyPlanProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // From Field
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _originController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Starting Stop / Origin',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _triggerSearch(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert_rounded, color: AppColors.textSecondary),
                tooltip: 'Swap Origin and Destination',
                onPressed: _swapStops,
              ),
            ],
          ),
          const Divider(height: 1),

          // To Field
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Destination Stop',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _triggerSearch(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Search Button
          BusSenseButton(
            label: 'Search Available Buses',
            icon: Icons.alt_route_rounded,
            variant: ButtonVariant.primary,
            onPressed: _triggerSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorPresets() {
    final presets = [
      (origin: 'Kaloor Metro Station, Kochi', dest: 'Vyttila Mobility Hub', label: 'Kaloor ➔ Vyttila'),
      (origin: 'Aluva Metro Station', dest: 'Ernakulam South Stand', label: 'Aluva ➔ South'),
      (origin: 'Fort Kochi Boat Jetty', dest: 'Infopark Phase 1', label: 'Fort Kochi ➔ Infopark'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ActionChip(
              backgroundColor: AppColors.white,
              elevation: 0,
              pressElevation: 0,
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
              label: Text(
                p.label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                _originController.text = p.origin;
                _destinationController.text = p.dest;
                _triggerSearch();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCorridorSummary(BuildContext context, JourneyPlanModel plan) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${plan.routeDistanceKm.toStringAsFixed(1)} km',
                style: AppTypography.tabularNumeral.copyWith(fontSize: 18),
              ),
              Text('Corridor Distance', style: AppTypography.labelSmall),
            ],
          ),
          Container(width: 1, height: 32, color: AppColors.border.withValues(alpha: 0.4)),
          Column(
            children: [
              Text(
                '${plan.estimatedTravelTimeMins} mins',
                style: AppTypography.tabularNumeral.copyWith(fontSize: 18, color: AppColors.secondary),
              ),
              Text('Estimated Transit Time', style: AppTypography.labelSmall),
            ],
          ),
          Container(width: 1, height: 32, color: AppColors.border.withValues(alpha: 0.4)),
          const Column(
            children: [
              BusSenseStatusBadge(label: 'RECOMMENDATION', tone: BadgeTone.accent),
              SizedBox(height: 2),
              Text('Data Source', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedHero(BuildContext context, BusRecommendationItem rec) {
    final crowdTone = switch (rec.crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    return InkWell(
      onTap: () {
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
      borderRadius: AppSpacing.roundedLg,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: AppColors.secondary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Recommended Badge & Fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BusSenseStatusBadge(label: 'RECOMMENDED FOR YOU', tone: BadgeTone.accent),
                Text(
                  '₹${rec.fareInr.toStringAsFixed(0)}',
                  style: AppTypography.tabularNumeral.copyWith(fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Bus & Route Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    rec.busNumber,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.accent,
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
                      Text('Operator: ${rec.operatorType}', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rec.etaMins} min',
                      style: AppTypography.tabularNumeral.copyWith(fontSize: 20, color: AppColors.secondary),
                    ),
                    Text('Arrives In', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Metrics row: Crowd + Savings
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
                    '${rec.occupancyPct.toStringAsFixed(0)}% Occupied',
                    style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (rec.crowdSavingVsAlternativePct != null) ...[
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${rec.crowdSavingVsAlternativePct!.toStringAsFixed(0)}% lower crowd',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Explanation Text
            Text(
              rec.whyRecommended,
              style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),

            // Book Boarding Pass Action
            BusSenseButton(
              label: 'Book Ticket (₹${rec.fareInr.toStringAsFixed(0)})',
              icon: Icons.confirmation_number_rounded,
              variant: ButtonVariant.primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TicketBookingScreen(
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
                        currentStop: _originController.text,
                        nextStop: _destinationController.text,
                        etaNextStopMins: rec.etaMins,
                        dataOrigin: rec.dataOrigin,
                      ),
                      initialOrigin: _originController.text,
                      initialDestination: _destinationController.text,
                      initialFare: rec.fareInr,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(BuildContext context, BusRecommendationItem alt) {
    final crowdTone = switch (alt.crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusDetailsScreen(
              bus: BusModel(
                busId: 'alt-${alt.busNumber}',
                busNumber: alt.busNumber,
                registrationNumber: 'KL-07-CF-1402',
                operatorType: alt.operatorType,
                routeNumber: alt.routeNumber,
                routeName: alt.routeName,
                capacity: 45,
                passengerCount: (45 * (alt.occupancyPct / 100.0)).round(),
                occupancyPct: alt.occupancyPct,
                crowdLevel: alt.crowdLevel,
                speedKmh: 30.0,
                headingDeg: 85.0,
                latitude: 9.9703,
                longitude: 76.2487,
                currentStop: 'En route',
                nextStop: 'Transit Stand',
                etaNextStopMins: alt.etaMins,
                dataOrigin: alt.dataOrigin,
              ),
            ),
          ),
        );
      },
      borderRadius: AppSpacing.roundedMd,
      child: Container(
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
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alt.routeName, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                      Text('${alt.operatorType} • ₹${alt.fareInr.toStringAsFixed(0)}', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${alt.etaMins} min',
                      style: AppTypography.tabularNumeral.copyWith(fontSize: 18),
                    ),
                    Text('ETA', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                BusSenseStatusBadge(label: alt.crowdLevel.value, tone: crowdTone),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${alt.occupancyPct.toStringAsFixed(0)}% Occupied',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
