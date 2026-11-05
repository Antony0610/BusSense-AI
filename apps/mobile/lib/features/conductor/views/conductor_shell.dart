import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_logo.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/conductor_providers.dart';
import 'active_trip_cockpit_view.dart';
import 'conductor_alerts_view.dart';
import 'conductor_bus_view.dart';
import 'conductor_profile_view.dart';
import 'qr_ticket_validator_view.dart';

/// Unified Conductor Mobile Shell — Google Stitch Design System
/// Duty HUD, QR ticket validator & vehicle occupancy updater.
class ConductorShell extends ConsumerStatefulWidget {
  final UserModel user;
  const ConductorShell({super.key, required this.user});

  @override
  ConsumerState<ConductorShell> createState() => _ConductorShellState();
}

class _ConductorShellState extends ConsumerState<ConductorShell> {
  int _currentIndex = 0;

  static const List<String> _tabTitles = [
    'Active Trip HUD',
    'QR Pass Scanner',
    'Vehicle Telemetry',
    'Crew Alerts',
    'Crew Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final shift = ref.watch(conductorShiftProvider).valueOrNull;
    final busNum = shift?.busNumber ?? '205';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const BusSenseLogo(size: 30),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _tabTitles[_currentIndex],
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'BusSense AI',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CONDUCTOR',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Sign Out',
                    icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            ActiveTripCockpitView(
              user: widget.user,
              onNavigateToScan: () => setState(() => _currentIndex = 1),
            ),
            QrTicketValidatorView(busNumber: busNum),
            const ConductorBusView(),
            const ConductorAlertsView(),
            ConductorProfileView(user: widget.user),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.border.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.navigation_outlined, 'Trip', activeIcon: Icons.navigation_rounded),
                _buildNavItem(1, Icons.qr_code_scanner_rounded, 'Scan'),
                _buildNavItem(2, Icons.directions_bus_outlined, 'Bus', activeIcon: Icons.directions_bus_rounded),
                _buildNavItem(3, Icons.warning_amber_rounded, 'Alerts', activeIcon: Icons.warning_rounded),
                _buildNavItem(4, Icons.badge_outlined, 'Profile', activeIcon: Icons.badge_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {IconData? activeIcon}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
