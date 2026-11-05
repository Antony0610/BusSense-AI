import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/conductor_shift_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';
import 'bus_pairing_screen.dart';
import 'conductor_incident_screen.dart';
import 'conductor_occupancy_screen.dart';
import 'shift_check_in_screen.dart';
import 'trip_completion_screen.dart';

/// Primary Conductor Operational Cockpit View (Tab 0: Trip)
class ActiveTripCockpitView extends ConsumerWidget {
  final UserModel user;
  final VoidCallback? onNavigateToScan;

  const ActiveTripCockpitView({
    super.key,
    required this.user,
    this.onNavigateToScan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftAsync = ref.watch(conductorShiftProvider);

    return shiftAsync.when(
      loading: () => const BusSenseLoading(message: 'Loading active trip cockpit...'),
      error: (err, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text('Failed to load cockpit telemetry', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            BusSenseButton(
              label: 'Retry',
              variant: ButtonVariant.outline,
              onPressed: () => ref.read(conductorShiftProvider.notifier).fetchShift(),
            ),
          ],
        ),
      ),
      data: (shift) {
        // If not checked in, present check-in prompt
        if (!shift.isCheckedIn) {
          return _buildNotCheckedInView(context, shift);
        }

        // Active operational trip
        final trip = shift.activeTrip ?? ConductorTripModel(
          tripId: 'trip-sim-${shift.busNumber}',
          tripCode: 'TRIP-${shift.busNumber}-ACTIVE',
          busNumber: shift.busNumber,
          routeNumber: shift.routeNumber,
          origin: 'Aluva Metro Station',
          destination: 'Vyttila Mobility Hub',
          currentStop: 'Palarivattom Jn',
          nextStop: 'Kaloor Central Stand',
          status: 'ACTIVE',
        );

        return SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Safety Warning Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.accent, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'SAFETY NOTICE: Use cockpit controls only when vehicle is safely stopped.',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 1. Operational Trip Header Card
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VEHICLE & CORRIDOR', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text('BUS ${trip.busNumber}', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(width: AppSpacing.sm),
                              BusSenseStatusBadge(label: 'ROUTE ${trip.routeNumber}', tone: BadgeTone.info),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    BusSenseStatusBadge(
                      label: trip.status,
                      tone: trip.isActive ? BadgeTone.success : BadgeTone.neutral,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Big Glanceable Stops Advancement HUD
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Stop
                    Text('CURRENT STOP', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(
                      trip.currentStop,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Next Approaching Stop
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('NEXT STOP', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.nextStop,
                      style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.secondary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Destination Terminus & Route Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Terminus: ${trip.destination}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Stop 5 of 8', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: trip.progressPct,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Glanceable Operational Metrics (ETA + Occupancy)
              Row(
                children: [
                  // Next Stop ETA
                  Expanded(
                    child: Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT STOP ETA', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('${trip.etaMinutes} MIN', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text('On-Time Corridor', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Occupancy Pill
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ConductorOccupancyScreen(busNumber: trip.busNumber)),
                          );
                        },
                        borderRadius: AppSpacing.roundedMd,
                        child: Container(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'CABIN LOAD',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${trip.occupancyPct.toStringAsFixed(0)}% ${trip.crowdLevel}',
                                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900, color: AppColors.secondary),
                              ),
                              const SizedBox(height: 2),
                              Text('23 / 55 aboard', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Primary Operational Quick Actions (Large Touch Targets)
              Text('PRIMARY COCKPIT CONTROLS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: AppSpacing.sm),

              // Button 1: View Occupancy
              BusSenseButton(
                label: 'View Occupancy & Seating Gauge',
                variant: ButtonVariant.primary,
                icon: Icons.people_outline_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ConductorOccupancyScreen(busNumber: trip.busNumber)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Button 2: Scan QR Ticket
              BusSenseButton(
                label: 'Scan Passenger QR Pass',
                variant: ButtonVariant.secondary,
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () {
                  if (onNavigateToScan != null) {
                    onNavigateToScan!();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Button 3: Report Incident / Hazard
              BusSenseButton(
                label: 'Report Route / Vehicle Incident',
                variant: ButtonVariant.outline,
                icon: Icons.report_problem_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConductorIncidentScreen(
                        busNumber: trip.busNumber,
                        routeNumber: trip.routeNumber,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Button 4: End / Complete Trip
              BusSenseButton(
                label: 'Complete Trip & Start Layover',
                variant: ButtonVariant.outline,
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TripCompletionScreen(trip: trip)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotCheckedInView(BuildContext context, ConductorShiftModel shift) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingScreen,
        child: Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('Duty Shift Not Started', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Please complete shift check-in and verify your assigned vehicle before accessing the operational cockpit.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              BusSenseButton(
                label: 'Check In for Duty',
                variant: ButtonVariant.primary,
                icon: Icons.login_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ShiftCheckInScreen(user: user)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              BusSenseButton(
                label: 'Verify Vehicle Pairing',
                variant: ButtonVariant.outline,
                icon: Icons.alt_route_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusPairingScreen()),
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
