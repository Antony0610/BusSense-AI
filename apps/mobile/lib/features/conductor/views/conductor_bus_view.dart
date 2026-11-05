import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';
import 'bus_pairing_screen.dart';
import 'conductor_occupancy_screen.dart';

/// Conductor Tab 2: Operational Vehicle Summary
class ConductorBusView extends ConsumerWidget {
  const ConductorBusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftAsync = ref.watch(conductorShiftProvider);

    return shiftAsync.when(
      loading: () => const BusSenseLoading(message: 'Retrieving vehicle operational telemetry...'),
      error: (err, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text('Failed to load vehicle status', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            BusSenseButton(
              label: 'Retry',
              variant: ButtonVariant.outline,
              onPressed: () => ref.refresh(conductorShiftProvider),
            ),
          ],
        ),
      ),
      data: (shift) {
        final busNumber = shift.busNumber;
        final routeNumber = shift.routeNumber;
        final trip = shift.activeTrip;

        return SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Overview Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ASSIGNED VEHICLE', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text('BUS $busNumber', style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const BusSenseStatusBadge(label: 'READY FOR TRANSIT', tone: BadgeTone.success),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Model: Ashok Leyland Electric 12M Low-Floor AC', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    const Divider(height: AppSpacing.lg),

                    _buildInfoRow('Corridor Route', 'Route $routeNumber (Aluva ➔ Vyttila Hub)'),
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow('Trip Status', trip?.status ?? 'ACTIVE'),
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow('Current Stop', trip?.currentStop ?? 'Palarivattom Jn'),
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow('Next Stop', trip?.nextStop ?? 'Kaloor Central Stand'),
                    const SizedBox(height: AppSpacing.xs),
                    _buildInfoRow('Occupancy', '${trip?.occupancyPct.toStringAsFixed(1) ?? "41.8"}% (${trip?.crowdLevel ?? "LOW"})'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Operational Subsystems Status Card
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
                    Text('Operational Subsystems', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSubsystemRow(Icons.battery_charging_full_rounded, 'Battery / Range', '78% SOC (142 km remaining)', AppColors.secondary),
                    const Divider(height: AppSpacing.sm),
                    _buildSubsystemRow(Icons.ac_unit_rounded, 'Cabin HVAC / AC', '24.0°C Setpoint • Active', AppColors.primary),
                    const Divider(height: AppSpacing.sm),
                    _buildSubsystemRow(Icons.meeting_room_outlined, 'Pneumatic Doors', 'Interlock OK • Synchronized', AppColors.secondary),
                    const Divider(height: AppSpacing.sm),
                    _buildSubsystemRow(Icons.sensors_rounded, 'Vision Telemetry', 'YOLOv8 Edge Unit Active', AppColors.secondary),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Truth Disclosure
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'SIMULATED TELEMETRY: Vehicle subsystem statuses synchronize with local corridor simulation loop.',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions
              BusSenseButton(
                label: 'View Detailed Cabin Occupancy',
                variant: ButtonVariant.primary,
                icon: Icons.people_outline_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ConductorOccupancyScreen(busNumber: busNumber)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              BusSenseButton(
                label: 'Re-assign / Pair Different Bus',
                variant: ButtonVariant.outline,
                icon: Icons.alt_route_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusPairingScreen()),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSubsystemRow(IconData icon, String title, String status, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              Text(status, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
