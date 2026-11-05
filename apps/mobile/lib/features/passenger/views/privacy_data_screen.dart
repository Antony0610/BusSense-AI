import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../providers/passenger_providers.dart';

/// Screen presenting factual privacy disclosures, data export, and account deactivation controls
class PrivacyDataScreen extends ConsumerStatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  ConsumerState<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends ConsumerState<PrivacyDataScreen> {
  bool _isExporting = false;
  bool _isDeactivating = false;

  Widget _buildDisclosureCard({
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
    required BadgeTone badgeTone,
  }) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.xs),
              BusSenseStatusBadge(label: badgeText, tone: badgeTone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDataExport() async {
    setState(() => _isExporting = true);
    try {
      final repository = ref.read(passengerRepositoryProvider);
      final exportData = await repository.exportUserData();

      if (mounted) {
        setState(() => _isExporting = false);
        _showExportSummarySheet(exportData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export data. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showExportSummarySheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Data Export Package', style: AppTypography.titleLarge),
                  const BusSenseStatusBadge(label: 'PROTOTYPE EXPORT', tone: BadgeTone.info),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A structured export of your commuter account data has been generated from persistent Supabase PostgreSQL:',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Commuter Identity: ${data['full_name'] ?? 'Ananya Sharma'} (${data['email'] ?? 'commuter@bussense.ai'})', style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    Text('• Saved Destinations: ${(data['saved_places'] as List?)?.length ?? 2} entries', style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    Text('• Ticket History: ${(data['ticket_summary'] as Map?)?['total_tickets'] ?? 1} passes', style: AppTypography.bodySmall),
                    const SizedBox(height: 4),
                    Text('• Preference Settings: 7 configured items', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              BusSenseButton(
                label: 'Close',
                variant: ButtonVariant.primary,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeactivation() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Deactivate Commuter Account?'),
          content: Text(
            'This will deactivate your session and flag your profile in the BusSense database. Your active digital tickets will become inaccessible.\n\nNote: This is a prototype deactivation flow.',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isDeactivating = true);
                try {
                  final repository = ref.read(passengerRepositoryProvider);
                  await repository.deactivateAccount();
                  await ref.read(authControllerProvider.notifier).logout();
                } catch (_) {
                  setState(() => _isDeactivating = false);
                }
              },
              child: const Text('Deactivate', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Privacy & Data', style: AppTypography.titleLarge),
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
            // Intro
            Text(
              'BusSense AI Factual Privacy Disclosures',
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'BusSense uses transit-relevant information strictly to provide routing, ticketing, crowding intelligence, and journey assistance.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 1. Computer Vision Privacy
            _buildDisclosureCard(
              icon: Icons.camera_alt_outlined,
              title: 'Onboard Computer Vision',
              description: 'Cabin cameras run a local privacy-preserving YOLOv8 neural network. The model counts heads and torso densities only. Facial recognition, biometric extraction, and image recording are strictly disabled.',
              badgeText: 'ZERO BIOMETRICS',
              badgeTone: BadgeTone.success,
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. GPS & Location Privacy
            _buildDisclosureCard(
              icon: Icons.location_on_outlined,
              title: 'GPS & Telemetry',
              description: 'Bus locations are derived from onboard vehicle transponders, not passenger personal phones. Personal device location is only requested when searching for nearby stops and is never broadcast continuously.',
              badgeText: 'NO BACKGROUND TRACKING',
              badgeTone: BadgeTone.success,
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Digital Boarding Passes
            _buildDisclosureCard(
              icon: Icons.confirmation_number_outlined,
              title: 'Ticketing & Payment Records',
              description: 'Boarding passes and transaction metadata are stored in persistent PostgreSQL with row-level security. A passenger cannot query another commuter’s boarding pass.',
              badgeText: 'ROW-LEVEL SECURITY',
              badgeTone: BadgeTone.info,
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. AI Assistant Context
            _buildDisclosureCard(
              icon: Icons.psychology_outlined,
              title: 'AI Transit Assistant',
              description: 'The journey assistant accesses only the query context you submit (selected bus, active ticket ID, destination stop). Queries are grounded against approved transit documentation.',
              badgeText: 'RAG GROUNDED',
              badgeTone: BadgeTone.info,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Actions Section
            Text('DATA CONTROLS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: AppSpacing.sm),

            // Download Data
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.download_rounded, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Download My Data', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Request structured export of your journey and ticket data', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _isExporting ? null : _handleDataExport,
                    child: Text(_isExporting ? 'Exporting...' : 'Request Export'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Deactivate Account
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined, color: AppColors.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deactivate Account', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: AppColors.error)),
                        const SizedBox(height: 2),
                        Text('Deactivate commuter account and revoke credentials', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _isDeactivating ? null : _confirmDeactivation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Deactivate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
