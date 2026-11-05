import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_logo.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import 'passenger_assistant_view.dart';
import 'passenger_explore_view.dart';
import 'passenger_home_view.dart';
import 'passenger_profile_view.dart';
import 'passenger_tickets_view.dart';
import 'notification_center_screen.dart';
import '../providers/passenger_providers.dart';

/// Unified Passenger Mobile Shell — Google Stitch Design System
/// Official Design Project 14259704318600090723
class PassengerShell extends ConsumerStatefulWidget {
  final UserModel user;
  const PassengerShell({super.key, required this.user});

  @override
  ConsumerState<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends ConsumerState<PassengerShell> {
  int _currentIndex = 0;

  static const List<String> _tabTitles = [
    'Live Departures',
    'Explore Corridors',
    'Digital Tickets',
    'AI Assistant',
    'Commuter Profile',
  ];

  @override
  Widget build(BuildContext context) {
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
                  // Stitch Brand Emblem
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

                  // Brand Title & Active Section
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
                                letterSpacing: 0.5,
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

                  // Passenger Persona Badge
                  const BusSenseStatusBadge(
                    label: 'PASSENGER',
                    tone: BadgeTone.success,
                  ),
                  const SizedBox(width: 6),

                  // Live Sync Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sensors_rounded, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 3),
                        Text(
                          'Live Sync',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Notification Center
                  Consumer(
                    builder: (context, ref, _) {
                      final unread = ref.watch(unreadNotificationsCountProvider);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Notifications',
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                              );
                            },
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Profile / Switch Account
                  InkWell(
                    onTap: () {
                      _showAccountBottomSheet(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildCurrentTab(),
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
                _buildNavItem(0, Icons.departure_board_rounded, 'Home'),
                _buildNavItem(1, Icons.alt_route_rounded, 'Explore'),
                _buildNavItem(2, Icons.confirmation_number_outlined, 'Tickets', activeIcon: Icons.confirmation_number_rounded),
                _buildNavItem(3, Icons.psychology_outlined, 'AI', activeIcon: Icons.psychology_rounded),
                _buildNavItem(4, Icons.person_outline_rounded, 'Profile', activeIcon: Icons.person_rounded),
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

  void _showAccountBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.user.fullName, style: AppTypography.titleMedium),
                          Text(widget.user.email, style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            'ROLE: ${widget.user.role.value.toUpperCase()}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                  title: const Text('Switch Role / Account'),
                  subtitle: const Text('Return to Unified Login Screen'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return PassengerHomeView(
          user: widget.user,
          onNavigateToExplore: () => setState(() => _currentIndex = 1),
        );

      case 1:
        return const PassengerExploreView();

      case 2:
        return PassengerTicketsView(
          onExploreRoutes: () => setState(() => _currentIndex = 1),
        );

      case 3:
        return PassengerAssistantView(
          onNavigateToExplore: () => setState(() => _currentIndex = 1),
          onNavigateToTickets: () => setState(() => _currentIndex = 2),
        );

      case 4:
      default:
        return PassengerProfileView(
          user: widget.user,
          onNavigateToExplore: () => setState(() => _currentIndex = 1),
          onNavigateToTickets: () => setState(() => _currentIndex = 2),
        );
    }
  }
}
