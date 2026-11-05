import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';
import 'bus_pairing_screen.dart';

/// Conductor Shift Check-In & Duty Assignment Screen
class ShiftCheckInScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback? onShiftStarted;

  const ShiftCheckInScreen({super.key, required this.user, this.onShiftStarted});

  @override
  ConsumerState<ShiftCheckInScreen> createState() => _ShiftCheckInScreenState();
}

class _ShiftCheckInScreenState extends ConsumerState<ShiftCheckInScreen> {
  bool _isLoading = false;

  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);
    await ref.read(conductorShiftProvider.notifier).checkIn(dutyId: 'DUTY-KL-402');
    if (mounted) {
      setState(() => _isLoading = false);
      if (widget.onShiftStarted != null) {
        widget.onShiftStarted!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shift duty started. Proceeding to active cockpit.'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftAsync = ref.watch(conductorShiftProvider);
    final shift = shiftAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Crew Shift Check-In', style: AppTypography.titleLarge),
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
            // Staff & Duty Card
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
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'C',
                          style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.user.fullName, style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              'Staff ID: ${widget.user.id.length >= 8 ? widget.user.id.substring(0, 8).toUpperCase() : widget.user.id.toUpperCase()}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const BusSenseStatusBadge(label: 'CONDUCTOR', tone: BadgeTone.accent),
                    ],
                  ),
                  const Divider(height: AppSpacing.xl),

                  // Duty Details
                  _buildDutyRow('Duty Roster ID', shift?.dutyId ?? 'DUTY-KL-402'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDutyRow('Assigned Shift', shift?.shiftName ?? 'Morning Peak Corridor Shift'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDutyRow('Duty Hours', shift?.shiftHours ?? '06:00 – 14:00'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDutyRow('Corridor Depot', 'Kaloor Operating Center (KOC)'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDutyRow('Assigned Bus', 'Bus ${shift?.busNumber ?? "205"} (Ashok Leyland)'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDutyRow('Primary Route', 'Route ${shift?.routeNumber ?? "12"} (Aluva ➔ Vyttila Hub)'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Truth & Prototype Disclosure Card
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BusSenseStatusBadge(label: 'SIMULATED ASSIGNMENT', tone: BadgeTone.info),
                        const SizedBox(height: 4),
                        Text(
                          'Duty pairings reflect local Greater Kochi corridor schedules. No direct KSRTC depot ERP integration claimed.',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Primary Check-In Button
            BusSenseButton(
              label: _isLoading ? 'Checking In...' : 'Start Shift Duty',
              variant: ButtonVariant.primary,
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handleCheckIn,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Secondary Pairing Button
            BusSenseButton(
              label: 'Change Vehicle / Route Pairing',
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
    );
  }

  Widget _buildDutyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
