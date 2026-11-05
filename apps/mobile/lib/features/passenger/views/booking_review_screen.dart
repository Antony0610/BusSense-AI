import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'test_payment_screen.dart';

/// Booking Review Screen before committing payment
class BookingReviewScreen extends StatelessWidget {
  final BookingDraft draft;

  const BookingReviewScreen({super.key, required this.draft});

  @override
  Widget build(BuildContext context) {
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
            Text('Booking Review', style: AppTypography.titleLarge),
            Text('Step 2 of 3: Verification', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BusSenseStatusBadge(label: 'BEFORE PAYMENT', tone: BadgeTone.neutral),
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
              // Main Review Card
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
                    // Bus Identifier Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Text(
                            draft.busNumber,
                            style: AppTypography.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(draft.routeName, style: AppTypography.titleMedium),
                              Text('${draft.operatorType} • Unreserved Carriage', style: AppTypography.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),

                    // Route Trajectory
                    _buildTrajectoryStep(
                      icon: Icons.trip_origin_rounded,
                      iconColor: AppColors.secondary,
                      title: 'Boarding Point',
                      stopName: draft.originStop,
                      subtitle: 'Expected departure: in ${draft.etaMins} mins',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Container(width: 2, height: 28, color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    _buildTrajectoryStep(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.error,
                      title: 'Destination',
                      stopName: draft.destinationStop,
                      subtitle: 'Direct corridor transit',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // Passenger Info
                    Text('Passenger Name', style: AppTypography.labelSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(draft.passengerName, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // Fare Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Fare (1 Passenger)', style: AppTypography.bodyMedium),
                        Text('₹${draft.fareAmount.toStringAsFixed(0)}', style: AppTypography.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Convenience Fee / Taxes', style: AppTypography.bodyMedium),
                        Text('₹0.00', style: AppTypography.bodyLarge.copyWith(color: AppColors.secondary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount Payable', style: AppTypography.titleMedium),
                        Text(
                          '₹${draft.fareAmount.toStringAsFixed(0)}',
                          style: AppTypography.tabularNumeral.copyWith(fontSize: 26, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              BusSenseButton(
                label: 'Proceed to Payment',
                icon: Icons.payment_rounded,
                variant: ButtonVariant.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TestPaymentScreen(draft: draft)),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              BusSenseButton(
                label: 'Edit Booking Details',
                icon: Icons.edit_outlined,
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrajectoryStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String stopName,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelSmall),
              Text(stopName, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
              Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
