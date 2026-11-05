import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/passenger_providers.dart';
import 'booking_review_screen.dart';

/// Ticket Booking & Journey Selection Screen
class TicketBookingScreen extends ConsumerStatefulWidget {
  final BusModel? bus;
  final String? initialOrigin;
  final String? initialDestination;
  final double? initialFare;

  const TicketBookingScreen({
    super.key,
    this.bus,
    this.initialOrigin,
    this.initialDestination,
    this.initialFare,
  });

  @override
  ConsumerState<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends ConsumerState<TicketBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _passengerNameController;
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  late double _fareAmount;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final userFullName = switch (authState) {
      Authenticated(user: final u) => u.fullName,
      _ => 'Commuter',
    };

    _passengerNameController = TextEditingController(text: userFullName);
    _originController = TextEditingController(
      text: widget.initialOrigin ?? widget.bus?.currentStop ?? 'Kaloor Metro Station, Kochi',
    );
    _destinationController = TextEditingController(
      text: widget.initialDestination ?? (widget.bus?.nextStop.isNotEmpty == true ? widget.bus!.nextStop : 'Vyttila Mobility Hub'),
    );
    _fareAmount = widget.initialFare ?? 25.0;
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _proceedToReview() {
    if (!_formKey.currentState!.validate()) return;

    final draft = BookingDraft(
      busNumber: widget.bus?.busNumber ?? '205',
      routeNumber: widget.bus?.routeNumber ?? '12',
      routeName: widget.bus?.routeName ?? 'Aluva Metro ➔ Vyttila Mobility Hub via Kaloor',
      operatorType: widget.bus?.operatorType ?? 'KSRTC',
      originStop: _originController.text.trim(),
      destinationStop: _destinationController.text.trim(),
      passengerName: _passengerNameController.text.trim(),
      fareAmount: _fareAmount,
      etaMins: widget.bus?.etaNextStopMins ?? 5,
      crowdLevel: widget.bus?.crowdLevel ?? CrowdLevel.low,
    );

    ref.read(currentBookingDraftProvider.notifier).state = draft;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingReviewScreen(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bus = widget.bus;
    final crowdTone = switch (bus?.crowdLevel ?? CrowdLevel.low) {
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
            Text('Book Boarding Pass', style: AppTypography.titleLarge),
            Text('Step 1 of 3: Details & Fare', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Selected Card
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
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          bus?.busNumber ?? '205',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bus?.routeName ?? 'Aluva Metro ➔ Vyttila Hub', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                            Text('${bus?.operatorType ?? 'KSRTC'} • Reservation Service', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (bus != null) BusSenseStatusBadge(label: bus.crowdLevel.value, tone: crowdTone),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Journey Stops Section
                Text('Journey Stops', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),

                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _originController,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Boarding Stop',
                          prefixIcon: Icon(Icons.trip_origin_rounded, color: AppColors.secondary, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter boarding stop' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _destinationController,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Destination Stop',
                          prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.error, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter destination stop' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Passenger Details Section
                Text('Passenger Information', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.xs),

                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _passengerNameController,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Primary Passenger Name',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter passenger name' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Single ticket per boarding session. No assigned seat selection (unreserved stage carriage).',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Fare Summary Card
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Fare', style: AppTypography.labelSmall),
                          Text('Standard Kerala Stage Carriage Tariff', style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
                        ],
                      ),
                      Text(
                        '₹${_fareAmount.toStringAsFixed(0)}',
                        style: AppTypography.tabularNumeral.copyWith(fontSize: 26, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Continue Button
                BusSenseButton(
                  label: 'Continue to Review',
                  icon: Icons.arrow_forward_rounded,
                  variant: ButtonVariant.primary,
                  onPressed: _proceedToReview,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
