import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/ticket_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_empty_state.dart';
import '../../../shared/widgets/bussense_error_state.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'active_journey_screen.dart';
import 'digital_qr_ticket_screen.dart';

/// Passenger Tickets Tab Landing View - Digital Passes & History
class PassengerTicketsView extends ConsumerWidget {
  final VoidCallback onExploreRoutes;

  const PassengerTicketsView({super.key, required this.onExploreRoutes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(myTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () async => ref.refresh(myTicketsProvider),
          child: ticketsAsync.when(
            data: (tickets) {
              if (tickets.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.paddingScreen,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: BusSenseEmptyState(
                      title: 'No Digital Tickets',
                      message: 'You have not booked any digital transit passes yet. Plan a journey on Home or Explore to get your QR ticket.',
                      icon: Icons.confirmation_number_outlined,
                      action: BusSenseButton(
                        label: 'Explore Corridor Routes',
                        icon: Icons.alt_route_rounded,
                        variant: ButtonVariant.primary,
                        onPressed: onExploreRoutes,
                      ),
                    ),
                  ),
                );
              }

              // Identify active ticket (status VALID or BOOKED) vs historical
              final activeTickets = tickets.where((t) => t.status == 'VALID' || t.status == 'BOOKED').toList();
              final historicalTickets = tickets.where((t) => t.status != 'VALID' && t.status != 'BOOKED').toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: AppSpacing.paddingScreen,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Active Pass Section
                        if (activeTickets.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Active Boarding Pass', style: AppTypography.titleLarge),
                              const BusSenseStatusBadge(label: 'READY TO BOARD', tone: BadgeTone.success),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...activeTickets.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: _buildActiveTicketCard(context, t, ref),
                              )),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Past / Validated Tickets Section
                        if (historicalTickets.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Past Tickets', style: AppTypography.titleLarge),
                              Text('${historicalTickets.length} trips', style: AppTypography.labelSmall),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...historicalTickets.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _buildHistoricalTicketRow(context, t),
                              )),
                        ],
                      ]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const BusSenseLoading(message: 'Loading verified boarding passes...'),
            error: (err, _) => BusSenseErrorState(
              title: 'Unable to Load Tickets',
              message: err.toString(),
              onRetry: () => ref.refresh(myTicketsProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTicketCard(BuildContext context, TicketModel ticket, WidgetRef ref) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.secondary, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.1),
            blurRadius: 18,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  ticket.busNumber,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800),
                ),
              ),
              const BusSenseStatusBadge(label: 'VALID TICKET', tone: BadgeTone.success),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Route Trajectory
          Text(
            '${ticket.originStop} ➔ ${ticket.destinationStop}',
            style: AppTypography.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Ticket #${ticket.ticketNumber} • Passenger: ${ticket.passengerName}',
            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fare Paid', style: AppTypography.labelSmall),
                  Text('₹${ticket.fareAmount.toStringAsFixed(0)}', style: AppTypography.titleLarge),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DigitalQrTicketScreen(ticket: ticket)),
                      );
                    },
                    icon: const Icon(Icons.qr_code_rounded, size: 18, color: AppColors.primary),
                    label: const Text('Show QR', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(activeJourneyTicketProvider.notifier).state = ticket;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ActiveJourneyScreen(ticket: ticket)),
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18, color: AppColors.white),
                    label: const Text('Track HUD', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, elevation: 0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalTicketRow(BuildContext context, TicketModel ticket) {
    final statusTone = ticket.status == 'USED' ? BadgeTone.neutral : BadgeTone.error;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DigitalQrTicketScreen(ticket: ticket)),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Text(
                ticket.busNumber,
                style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ticket.originStop} ➔ ${ticket.destinationStop}',
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${ticket.ticketNumber} • ₹${ticket.fareAmount.toStringAsFixed(0)}',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            BusSenseStatusBadge(label: ticket.status, tone: statusTone),
          ],
        ),
      ),
    );
  }
}
