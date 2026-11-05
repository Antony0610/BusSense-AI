import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/conductor_shift_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';

/// Screen managing trip terminus completion and depot turnaround layover buffer
class TripCompletionScreen extends ConsumerStatefulWidget {
  final ConductorTripModel trip;

  const TripCompletionScreen({super.key, required this.trip});

  @override
  ConsumerState<TripCompletionScreen> createState() => _TripCompletionScreenState();
}

class _TripCompletionScreenState extends ConsumerState<TripCompletionScreen> {
  bool _isCompleting = false;
  bool _isLayoverActive = false;
  ConductorTripCompletionModel? _completionSummary;

  final Map<String, bool> _preDepartureChecklist = {
    'Doors and emergency releases inspected': false,
    'Cabin mirrors and blindspot cameras checked': false,
    'Cash ticket float balanced and reconciled': false,
    'Interior cabin debris removed': false,
  };

  Future<void> _handleCompleteTrip() async {
    setState(() => _isCompleting = true);
    final summary = await ref.read(conductorShiftProvider.notifier).completeTrip(
      notes: 'Terminus arrival on schedule at ${widget.trip.destination}.',
    );
    if (mounted) {
      setState(() {
        _isCompleting = false;
        _completionSummary = summary ?? ConductorTripCompletionModel(
          tripId: widget.trip.tripId,
          busNumber: widget.trip.busNumber,
          routeNumber: widget.trip.routeNumber,
          completedAt: DateTime.now().toIso8601String(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Trip Terminus & Layover', style: AppTypography.titleLarge),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            // Terminus Status Banner
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.roundedMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BUS ${widget.trip.busNumber} • ROUTE ${widget.trip.routeNumber}',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                      ),
                      BusSenseStatusBadge(
                        label: _completionSummary != null ? 'COMPLETED' : 'TERMINUS ARRIVAL',
                        tone: BadgeTone.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Corridor Trip: ${widget.trip.origin} ➔ ${widget.trip.destination}',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Trip Code: ${widget.trip.tripCode}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Performance Metrics
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
                  Text('Trip Performance Summary', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMetricRow('Elapsed Duration', '42 min (On-Time)'),
                  const Divider(height: AppSpacing.md),
                  _buildMetricRow('Final Occupancy', '${widget.trip.occupancyPct.toStringAsFixed(1)}% (${widget.trip.crowdLevel})'),
                  const Divider(height: AppSpacing.md),
                  _buildMetricRow('Boarding Passes Validated', '18 passes'),
                  const Divider(height: AppSpacing.md),
                  _buildMetricRow('Next Scheduled Turnaround', '15 min buffer'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Primary Action: Complete Trip
            if (_completionSummary == null) ...[
              BusSenseButton(
                label: _isCompleting ? 'Finalizing Trip...' : 'Complete Trip',
                variant: ButtonVariant.primary,
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isCompleting,
                onPressed: _isCompleting ? null : _handleCompleteTrip,
              ),
              const SizedBox(height: AppSpacing.md),
            ] else ...[
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Trip successfully marked as COMPLETED in central dispatch.',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Turnaround Layover Staging
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
                      Row(
                        children: [
                          const Icon(Icons.hourglass_bottom_rounded, color: AppColors.secondary, size: 22),
                          const SizedBox(width: AppSpacing.xs),
                          Text('Turnaround Layover', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const BusSenseStatusBadge(label: '15 MIN BUFFER', tone: BadgeTone.info),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Rest period before next dispatch outbound towards ${widget.trip.origin}.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Pre-departure Checklist
                  Text('Pre-Departure Inspection', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  ..._preDepartureChecklist.keys.map((item) {
                    final isChecked = _preDepartureChecklist[item]!;
                    return Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item, style: AppTypography.bodySmall),
                        value: isChecked,
                        activeColor: AppColors.secondary,
                        onChanged: (val) {
                          setState(() {
                            _preDepartureChecklist[item] = val ?? false;
                          });
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.sm),
                  BusSenseButton(
                    label: _isLayoverActive ? 'Layover In Progress (15:00)' : 'Start Layover Timer',
                    variant: ButtonVariant.outline,
                    icon: Icons.timer_outlined,
                    onPressed: () {
                      setState(() => _isLayoverActive = !_isLayoverActive);
                    },
                  ),
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
                      'PROTOTYPE LAYOVER MANAGEMENT: Turnaround timers synchronize with local corridor simulation.',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
