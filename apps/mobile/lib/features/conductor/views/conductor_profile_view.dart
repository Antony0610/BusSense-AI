import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/conductor_providers.dart';
import 'bus_pairing_screen.dart';
import 'shift_check_in_screen.dart';

/// Conductor Tab 4: Minimalist Crew Profile & Account Controls
class ConductorProfileView extends ConsumerWidget {
  final UserModel user;

  const ConductorProfileView({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(conductorShiftProvider).valueOrNull;

    return SingleChildScrollView(
      padding: AppSpacing.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Crew Identity Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.white,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: AppTypography.titleLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(user.email, style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: AppSpacing.xs),
                      const BusSenseStatusBadge(label: 'DRIVER / CONDUCTOR', tone: BadgeTone.accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Operational Assignment Card
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
                Text('OPERATIONAL DUTY DETAILS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: AppSpacing.sm),
                _buildProfileRow('Staff Duty ID', shift?.dutyId ?? 'DUTY-KL-402'),
                const Divider(height: AppSpacing.md),
                _buildProfileRow('Assigned Bus', 'Bus ${shift?.busNumber ?? "205"} (Ashok Leyland)'),
                const Divider(height: AppSpacing.md),
                _buildProfileRow('Active Corridor', 'Route ${shift?.routeNumber ?? "12"} (Aluva ➔ Vyttila Hub)'),
                const Divider(height: AppSpacing.md),
                _buildProfileRow('Shift Hours', shift?.shiftHours ?? '06:00 – 14:00'),
                const Divider(height: AppSpacing.md),
                _buildProfileRow('Pairing Status', shift?.pairingStatus ?? 'PAIRED'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Shift Actions
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
                Text('CREW ROSTER CONTROLS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
                const SizedBox(height: AppSpacing.sm),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.login_rounded, color: AppColors.secondary),
                    title: const Text('Shift Check-In & Duty Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Review roster duty assignment'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShiftCheckInScreen(user: user)),
                      );
                    },
                  ),
                ),
                const Divider(height: AppSpacing.xs),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alt_route_rounded, color: AppColors.secondary),
                    title: const Text('Vehicle & Route Pairing', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Re-assign active bus or route'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusPairingScreen()),
                      );
                    },
                  ),
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
                    'SIMULATED ASSIGNMENT: Crew assignments and duty hours operate under local test credentials.',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Primary Sign Out Action
          BusSenseButton(
            label: 'Sign Out',
            variant: ButtonVariant.outline,
            icon: Icons.logout_rounded,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
