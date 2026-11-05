import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/ticket_validation_result_model.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';

/// Conductor QR Boarding Pass Scanner & Ticket Validator
class QrTicketValidatorView extends ConsumerStatefulWidget {
  final String busNumber;

  const QrTicketValidatorView({super.key, this.busNumber = '205'});

  @override
  ConsumerState<QrTicketValidatorView> createState() => _QrTicketValidatorViewState();
}

class _QrTicketValidatorViewState extends ConsumerState<QrTicketValidatorView> {
  final TextEditingController _hashController = TextEditingController();

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _validateCode(String hash) async {
    await ref.read(ticketValidationProvider.notifier).validate(
      qrHash: hash,
      busNumber: widget.busNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final validationState = ref.watch(ticketValidationProvider);
    final result = validationState.result;

    return SingleChildScrollView(
      padding: AppSpacing.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Viewfinder Container
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Corner framing overlay
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 2.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.accent),
                  ),
                ),

                // Top honesty badge
                Positioned(
                  top: AppSpacing.md,
                  child: const BusSenseStatusBadge(
                    label: 'CAMERA SCAN DEFERRED • PROTOTYPE VIEW',
                    tone: BadgeTone.info,
                  ),
                ),

                // Scanning indicator
                if (validationState.isLoading)
                  const Positioned(
                    bottom: AppSpacing.md,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text('Verifying with central database...', style: TextStyle(color: AppColors.white, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Validation Result Card (if verified)
          if (result != null) ...[
            _buildResultCard(result),
            const SizedBox(height: AppSpacing.md),
          ],

          // Quick Simulation Controls
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rapid Test Scenarios', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                    const BusSenseStatusBadge(label: 'VERIFICATION', tone: BadgeTone.neutral),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Trigger simulated passenger ticket presentations to test atomic validation states.',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),

                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildScenarioButton(
                      label: 'Valid Pass',
                      color: AppColors.secondary,
                      onTap: () => _validateCode('sim-valid-qr-hash'),
                    ),
                    _buildScenarioButton(
                      label: 'Already Used',
                      color: AppColors.warning,
                      onTap: () => _validateCode('sim-used-qr-hash'),
                    ),
                    _buildScenarioButton(
                      label: 'Expired Pass',
                      color: AppColors.error,
                      onTap: () => _validateCode('sim-expired-qr-hash'),
                    ),
                    _buildScenarioButton(
                      label: 'Invalid QR',
                      color: AppColors.textSecondary,
                      onTap: () => _validateCode('sim-invalid-qr-hash'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Manual Code Entry
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
                Text('Manual Pass Verification', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enter ticket hash or numeric reference for commuters with damaged screen displays.',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hashController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'e.g. TKT-1042 or QR hash',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.roundedSm,
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                      ),
                      onPressed: () {
                        final text = _hashController.text.trim();
                        if (text.isNotEmpty) {
                          _validateCode(text);
                        }
                      },
                      child: const Text('Verify'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildResultCard(TicketValidationResultModel result) {
    Color cardBg;
    Color borderColor;
    BadgeTone badgeTone;
    IconData statusIcon;

    switch (result.status) {
      case ValidationStatus.valid:
        cardBg = AppColors.secondary.withValues(alpha: 0.08);
        borderColor = AppColors.secondary;
        badgeTone = BadgeTone.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ValidationStatus.alreadyUsed:
        cardBg = AppColors.warning.withValues(alpha: 0.08);
        borderColor = AppColors.warning;
        badgeTone = BadgeTone.warning;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case ValidationStatus.expired:
        cardBg = AppColors.error.withValues(alpha: 0.08);
        borderColor = AppColors.error;
        badgeTone = BadgeTone.error;
        statusIcon = Icons.timer_off_rounded;
        break;
      case ValidationStatus.invalid:
        cardBg = AppColors.surfaceVariant.withValues(alpha: 0.5);
        borderColor = AppColors.border;
        badgeTone = BadgeTone.neutral;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: borderColor, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                result.status.displayLabel,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: borderColor),
              ),
              const Spacer(),
              BusSenseStatusBadge(label: result.status.displayLabel, tone: badgeTone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(result.message, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const Divider(height: AppSpacing.md),

          if (result.ticketNumber != null) ...[
            _buildResultRow('Ticket ID', result.ticketNumber!),
            const SizedBox(height: AppSpacing.xxs),
          ],
          if (result.passengerName != null) ...[
            _buildResultRow('Passenger', result.passengerName!),
            const SizedBox(height: AppSpacing.xxs),
          ],
          if (result.destinationStop != null) ...[
            _buildResultRow('Destination', result.destinationStop!),
            const SizedBox(height: AppSpacing.xxs),
          ],

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Dismiss Result'),
              onPressed: () => ref.read(ticketValidationProvider.notifier).reset(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildScenarioButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ActionChip(
        avatar: Icon(Icons.play_arrow_rounded, color: color, size: 16),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        onPressed: onTap,
      ),
    );
  }
}
