import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/ticket_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_empty_state.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'digital_qr_ticket_screen.dart';

/// Passenger Active Journey HUD (Glanceable Onboard Experience)
class ActiveJourneyScreen extends ConsumerWidget {
  final TicketModel? ticket;

  const ActiveJourneyScreen({super.key, this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTicket = ticket ?? ref.watch(activeJourneyTicketProvider) ?? ref.watch(activeTicketProvider);

    if (currentTicket == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Active Journey', style: AppTypography.titleLarge),
        ),
        body: SafeArea(
          child: BusSenseEmptyState(
            title: 'No Active Journey',
            message: 'You have no confirmed boarding pass in transit. Select a bus and book a ticket to begin your trip.',
            icon: Icons.navigation_outlined,
            action: BusSenseButton(
              label: 'Explore Routes',
              icon: Icons.alt_route_rounded,
              variant: ButtonVariant.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }

    final busesAsync = ref.watch(liveBusesProvider);
    final alertsAsync = ref.watch(activeAlertsProvider);

    // Find live bus matching ticket if available
    final liveBus = busesAsync.value?.cast<BusModel?>().firstWhere(
          (b) => b?.busNumber == currentTicket.busNumber,
          orElse: () => null,
        );

    final currentStop = liveBus?.currentStop ?? currentTicket.originStop;
    final nextStop = liveBus?.nextStop ?? 'Approaching Junction';
    final etaMins = liveBus?.etaNextStopMins ?? 4;
    final crowdLevel = liveBus?.crowdLevel ?? CrowdLevel.low;

    final crowdTone = switch (crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Journey HUD', style: AppTypography.titleLarge),
            Text('Live Onboard Guidance', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
            tooltip: 'View QR Ticket',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DigitalQrTicketScreen(ticket: currentTicket)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            tooltip: 'Refresh Telemetry',
            onPressed: () => ref.refresh(liveBusesProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async => ref.refresh(liveBusesProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Current Bus Block
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppSpacing.roundedLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          currentTicket.busNumber,
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
                            Text(
                              'CURRENT BUS',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontSize: 10),
                            ),
                            Text(
                              'Route ${currentTicket.routeNumber}',
                              style: AppTypography.titleLarge.copyWith(color: AppColors.white),
                            ),
                            Text(
                              'Ticket #${currentTicket.ticketNumber}',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.white.withValues(alpha: 0.7), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      BusSenseStatusBadge(label: crowdLevel.value, tone: crowdTone),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Destination Guidance Block
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag_rounded, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR DESTINATION', style: AppTypography.labelSmall),
                            Text(
                              currentTicket.destinationStop,
                              style: AppTypography.titleMedium.copyWith(fontSize: 16),
                            ),
                            Text(
                              'Get off at this stop',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3 & 4. Next Stop & ETA Row
                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NEXT APPROACHING STOP', style: AppTypography.labelSmall),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              nextStop,
                              style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Departed: $currentStop',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$etaMins',
                                style: AppTypography.tabularNumeral.copyWith(
                                  fontSize: 36,
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
                          Text('ETA', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Visual Route Progress Milestones
                Text('Route Progress', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),

                Container(
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      // Boarding Milestone (Completed)
                      _buildMilestoneRow(
                        title: 'Boarded',
                        stopName: currentTicket.originStop,
                        isCompleted: true,
                        isActive: false,
                        isLast: false,
                      ),

                      // Next Stop Milestone (Active)
                      _buildMilestoneRow(
                        title: 'Approaching Next',
                        stopName: nextStop,
                        isCompleted: false,
                        isActive: true,
                        isLast: false,
                      ),

                      // Destination Milestone (Upcoming)
                      _buildMilestoneRow(
                        title: 'Destination',
                        stopName: currentTicket.destinationStop,
                        isCompleted: false,
                        isActive: false,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Active Alert Ticker if relevant
                alertsAsync.when(
                  data: (alerts) {
                    final routeAlerts = alerts
                        .where((a) => a.affectedRoute.contains(currentTicket.busNumber) || a.affectedRoute.contains(currentTicket.routeNumber))
                        .toList();
                    if (routeAlerts.isEmpty) return const SizedBox.shrink();
                    final alert = routeAlerts.first;
                    return Container(
                      padding: AppSpacing.paddingMd,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              alert.message,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Actions: QR Pass inspection
                BusSenseButton(
                  label: 'Show Digital QR Ticket',
                  icon: Icons.qr_code_rounded,
                  variant: ButtonVariant.primary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DigitalQrTicketScreen(ticket: currentTicket)),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Simulated Telemetry Badge with Live Freshness
                Center(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final freshness = ref.watch(telemetryFreshnessProvider);
                      final isStale = ref.watch(telemetryIsStaleProvider);
                      return Text(
                        'SIMULATED LIVE TELEMETRY • ${isStale ? "STALE DATA" : freshness}',
                        style: AppTypography.labelSmall.copyWith(
                          color: isStale ? AppColors.warning : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneRow({
    required String title,
    required String stopName,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    Color dotColor = AppColors.border;
    if (isCompleted) dotColor = AppColors.secondary;
    if (isActive) dotColor = AppColors.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.secondary : (isActive ? AppColors.warning : AppColors.white),
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: AppColors.white)
                  : (isActive ? const Center(child: CircleAvatar(radius: 3, backgroundColor: AppColors.white)) : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? AppColors.secondary : AppColors.border.withValues(alpha: 0.5),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isActive ? AppColors.warning : (isCompleted ? AppColors.secondary : AppColors.textSecondary),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                stopName,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }
}
