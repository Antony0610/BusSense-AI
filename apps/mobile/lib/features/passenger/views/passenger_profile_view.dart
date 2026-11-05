import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/passenger_providers.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'language_appearance_screen.dart';
import 'notification_preferences_screen.dart';
import 'passenger_explore_view.dart';
import 'privacy_data_screen.dart';
import 'report_issue_screen.dart';
import 'saved_places_screen.dart';

/// Primary Commuter Profile & Settings Hub
class PassengerProfileView extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onNavigateToTickets;

  const PassengerProfileView({
    super.key,
    required this.user,
    this.onNavigateToExplore,
    this.onNavigateToTickets,
  });

  @override
  ConsumerState<PassengerProfileView> createState() => _PassengerProfileViewState();
}

class _PassengerProfileViewState extends ConsumerState<PassengerProfileView> {
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_bus_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('About BusSense AI'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BusSense AI — Version 1.0.0 (Release H5 Batch 4)',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Climate-Smart Public Bus Intelligence Platform for Greater Kochi Transit Corridors.\n\nBuilt strictly with Google Stitch design system tokens (Deep Forest Green & Ivory light surfaces).',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              const BusSenseStatusBadge(label: 'ZERO BIOMETRICS • PRIVACY FIRST', tone: BadgeTone.success),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailingBadge,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.secondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              trailingBadge,
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPreferencesProvider);
    final savedPlacesAsync = ref.watch(savedPlacesProvider);
    final savedCount = savedPlacesAsync.valueOrNull?.length ?? 2;

    return SingleChildScrollView(
      padding: AppSpacing.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Commuter Identity Card
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  _currentUser.fullName.isNotEmpty ? _currentUser.fullName[0].toUpperCase() : 'P',
                  style: AppTypography.titleLarge.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.fullName,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentUser.email,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const BusSenseStatusBadge(label: 'PASSENGER', tone: BadgeTone.success),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          prefs.languageDisplay,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
                tooltip: 'Edit Profile',
                onPressed: () async {
                  final updated = await Navigator.push<UserModel>(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: _currentUser)),
                  );
                  if (updated != null) {
                    setState(() => _currentUser = updated);
                  }
                },
              ),
            ],
          ),
        ),

        // ACCOUNT SECTION
        _buildSectionTitle('Account'),
        _buildMenuRow(
          icon: Icons.person_outline_rounded,
          title: 'Edit Profile',
          subtitle: 'Name and profile preferences',
          onTap: () async {
            final updated = await Navigator.push<UserModel>(
              context,
              MaterialPageRoute(builder: (_) => EditProfileScreen(user: _currentUser)),
            );
            if (updated != null) {
              setState(() => _currentUser = updated);
            }
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        BusSenseButton(
          label: 'Sign Out',
          variant: ButtonVariant.outline,
          icon: Icons.logout_rounded,
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
        ),

        // TRAVEL SECTION
        _buildSectionTitle('Travel & Shortcuts'),
        _buildMenuRow(
          icon: Icons.bookmark_border_rounded,
          title: 'Saved Places',
          subtitle: '$savedCount destinations saved for 1-tap routing',
          trailingBadge: BusSenseStatusBadge(label: '$savedCount PLACES', tone: BadgeTone.info),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildMenuRow(
              icon: Icons.alt_route_rounded,
              title: 'Favorite Route',
              subtitle: 'Route 205 (Aluva ➔ Vyttila Mobility Hub)',
              onTap: () {
                if (widget.onNavigateToExplore != null) {
                  widget.onNavigateToExplore!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PassengerExploreView(initialDestination: 'Vyttila Mobility Hub')),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildMenuRow(
              icon: Icons.confirmation_number_outlined,
              title: 'Recent Journeys & Passes',
              subtitle: 'View your digital QR boarding passes',
              onTap: () {
                if (widget.onNavigateToTickets != null) {
                  widget.onNavigateToTickets!();
                }
              },
            ),

            // PREFERENCES SECTION
            _buildSectionTitle('Preferences'),
            _buildMenuRow(
              icon: Icons.translate_rounded,
              title: 'Language',
              subtitle: prefs.languageDisplay,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageAppearanceScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildMenuRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: prefs.masterNotifications ? 'Journey, Crowding & Service Alerts' : 'Notifications Paused',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildMenuRow(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: prefs.themeModeDisplay,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageAppearanceScreen()),
                );
              },
            ),

            // PRIVACY & CONTROL SECTION
            _buildSectionTitle('Privacy & Control'),
            _buildMenuRow(
              icon: Icons.shield_outlined,
              title: 'Privacy & Data Controls',
              subtitle: 'Zero biometrics, transponder telemetry & data export',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyDataScreen()),
                );
              },
            ),

            // SUPPORT SECTION
            _buildSectionTitle('Support & Feedback'),
            _buildMenuRow(
              icon: Icons.help_outline_rounded,
              title: 'Help & FAQ',
              subtitle: 'Crowd scoring, recommendations & boarding pass FAQ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildMenuRow(
              icon: Icons.report_problem_outlined,
              title: 'Report an Issue',
              subtitle: 'Submit vehicle, delay, or crowding feedback',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildMenuRow(
              icon: Icons.info_outline_rounded,
              title: 'About BusSense AI',
              subtitle: 'Version 1.0.0 (Release H5)',
              onTap: () => _showAboutDialog(context),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      );
  }
}
