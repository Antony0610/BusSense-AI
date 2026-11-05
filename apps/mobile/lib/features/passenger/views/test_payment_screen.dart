import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'digital_qr_ticket_screen.dart';

enum PaymentMethodOption {
  testUpi('Test UPI (Instant Simulator)', Icons.qr_code_2_rounded),
  testCard('Test Transit Card (Simulated)', Icons.credit_card_rounded),
  testNetBanking('Test NetBanking (Sandbox)', Icons.account_balance_rounded);

  final String label;
  final IconData icon;
  const PaymentMethodOption(this.label, this.icon);
}

/// Prototype & Test Payment Screen
class TestPaymentScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;

  const TestPaymentScreen({super.key, required this.draft});

  @override
  ConsumerState<TestPaymentScreen> createState() => _TestPaymentScreenState();
}

class _TestPaymentScreenState extends ConsumerState<TestPaymentScreen> {
  PaymentMethodOption _selectedMethod = PaymentMethodOption.testUpi;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _processPayment({required bool simulateFailure}) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (simulateFailure) {
        await Future.delayed(const Duration(milliseconds: 600));
        throw Exception('Simulated Payment Gateway Decline: Bank server timeout.');
      }

      // Call genuine backend endpoint to book ticket and persist payment record
      final repository = ref.read(passengerRepositoryProvider);
      final ticket = await repository.bookTicket(
        busNumber: widget.draft.busNumber,
        routeNumber: widget.draft.routeNumber,
        originStop: widget.draft.originStop,
        destinationStop: widget.draft.destinationStop,
        passengerName: widget.draft.passengerName,
        fareAmount: widget.draft.fareAmount,
        paymentMethod: _selectedMethod.name,
      );

      // Invalidate ticket list provider so Tickets tab reflects new ticket immediately
      ref.invalidate(myTicketsProvider);
      ref.read(activeJourneyTicketProvider.notifier).state = ticket;

      if (!mounted) return;

      // Navigate to Digital QR Ticket
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DigitalQrTicketScreen(ticket: ticket)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Gateway', style: AppTypography.titleLarge),
            Text('Step 3 of 3: Prototype Settlement', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BusSenseStatusBadge(label: 'SIMULATED PAYMENT', tone: BadgeTone.warning),
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
              // Amount Due Hero Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    Text('Total Amount Payable', style: AppTypography.labelSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '₹${widget.draft.fareAmount.toStringAsFixed(2)}',
                      style: AppTypography.tabularNumeral.copyWith(
                        fontSize: 36,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Bus ${widget.draft.busNumber} • ${widget.draft.originStop} ➔ ${widget.draft.destinationStop}',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Error State Banner if payment failed
              if (_errorMessage != null) ...[
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Failed', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
                            Text(_errorMessage!, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Simulated Payment Options
              Text('Simulated Payment Method', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.xs),

              ...PaymentMethodOption.values.map((method) {
                final isSelected = _selectedMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    onTap: _isProcessing ? null : () => setState(() => _selectedMethod = method),
                    borderRadius: AppSpacing.roundedMd,
                    child: Container(
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(
                          color: isSelected ? AppColors.secondary : AppColors.border.withValues(alpha: 0.35),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(method.icon, color: isSelected ? AppColors.secondary : AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              method.label,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppColors.secondary : AppColors.border,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),

              // Sandbox Safety Disclosure
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.45),
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Demo Sandbox: No real card or bank details are collected. Transactions are recorded as simulated test payments.',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Pay Success Action
              BusSenseButton(
                label: 'Pay ₹${widget.draft.fareAmount.toStringAsFixed(0)} (Simulate Success)',
                icon: Icons.check_circle_outline_rounded,
                variant: ButtonVariant.primary,
                isLoading: _isProcessing,
                onPressed: _isProcessing ? null : () => _processPayment(simulateFailure: false),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Simulate Failure Action (for testing failure handling)
              BusSenseButton(
                label: 'Simulate Payment Failure',
                icon: Icons.cancel_outlined,
                variant: ButtonVariant.outline,
                onPressed: _isProcessing ? null : () => _processPayment(simulateFailure: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
