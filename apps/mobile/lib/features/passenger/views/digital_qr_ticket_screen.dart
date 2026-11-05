import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/ticket_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'active_journey_screen.dart';

/// Digital Boarding Pass with Verified Conductor QR Token
class DigitalQrTicketScreen extends ConsumerWidget {
  final TicketModel ticket;

  const DigitalQrTicketScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusTone = switch (ticket.status.toUpperCase()) {
      'VALID' || 'BOOKED' => BadgeTone.success,
      'USED' => BadgeTone.neutral,
      'EXPIRED' => BadgeTone.warning,
      _ => BadgeTone.error,
    };

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () {
            ref.invalidate(myTicketsProvider);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digital Boarding Pass', style: AppTypography.titleLarge),
            Text('Kochi Transit • Passenger Ticket', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BusSenseStatusBadge(label: ticket.status, tone: statusTone),
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
              // Ticket Visual Canvas
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Ticket Header
                    Container(
                      padding: AppSpacing.paddingMd,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      child: Row(
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
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Route ${ticket.routeNumber}',
                                  style: AppTypography.titleMedium.copyWith(color: AppColors.white),
                                ),
                                Text(
                                  ticket.ticketNumber,
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.accent, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${ticket.fareAmount.toStringAsFixed(0)}',
                            style: AppTypography.tabularNumeral.copyWith(color: AppColors.white, fontSize: 22),
                          ),
                        ],
                      ),
                    ),

                    // Stops Trajectory
                    Padding(
                      padding: AppSpacing.paddingLg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin_rounded, color: AppColors.secondary, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Boarding Stop', style: AppTypography.labelSmall),
                                    Text(ticket.originStop, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(width: 2, height: 20, color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Destination Stop', style: AppTypography.labelSmall),
                                    Text(ticket.destinationStop, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Perforated Divider
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Flex(
                                direction: Axis.horizontal,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  (constraints.constrainWidth() / 10).floor(),
                                  (_) => SizedBox(
                                    width: 5,
                                    height: 1.5,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.5)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // High Contrast QR Code Presentation
                    Padding(
                      padding: AppSpacing.paddingLg,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                            ),
                            child: _buildQrCode(ticket),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Scan with Conductor Terminal',
                            style: AppTypography.labelLarge.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Passenger: ${ticket.passengerName}',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Valid for 4 hours from booking',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Honesty & Prototype Notice
              Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  'PROTOTYPE DIGITAL TICKET • PERSISTED IN SUPABASE POSTGRESQL',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Track Active Journey CTA
              BusSenseButton(
                label: 'Track Active Journey HUD',
                icon: Icons.navigation_rounded,
                variant: ButtonVariant.primary,
                onPressed: () {
                  ref.read(activeJourneyTicketProvider.notifier).state = ticket;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ActiveJourneyScreen(ticket: ticket)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              BusSenseButton(
                label: 'Return to Commuter Home',
                icon: Icons.home_rounded,
                variant: ButtonVariant.outline,
                onPressed: () {
                  ref.invalidate(myTicketsProvider);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCode(TicketModel ticket) {
    // 1. Prefer base64 image if valid URI returned by backend ticket service
    if (ticket.qrCodeDataUri.startsWith('data:image/png;base64,')) {
      try {
        final base64Str = ticket.qrCodeDataUri.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        );
      } catch (_) {}
    }

    // 2. High-contrast vector QR fallback using qr_flutter
    final qrPayload = ticket.qrCodeHash.isNotEmpty ? ticket.qrCodeHash : ticket.ticketNumber;
    return QrImageView(
      data: qrPayload,
      version: QrVersions.auto,
      size: 180.0,
      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
    );
  }
}
