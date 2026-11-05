import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';

/// Screen allowing conductor to pair with an active vehicle and corridor route
class BusPairingScreen extends ConsumerStatefulWidget {
  const BusPairingScreen({super.key});

  @override
  ConsumerState<BusPairingScreen> createState() => _BusPairingScreenState();
}

class _BusPairingScreenState extends ConsumerState<BusPairingScreen> {
  String _selectedBus = '205';
  String _selectedRoute = '12';
  bool _isSaving = false;

  static const List<Map<String, String>> kFleetOptions = [
    {
      'bus': '205',
      'route': '12',
      'corridor': 'Aluva Metro ➔ Vyttila Mobility Hub',
      'type': 'Ashok Leyland Electric (AC)',
    },
    {
      'bus': '14A',
      'route': '3B',
      'corridor': 'Angamaly Stand ➔ Menaka / High Court',
      'type': 'KSRTC Fast Passenger',
    },
    {
      'bus': '12',
      'route': '7',
      'corridor': 'Kaloor Stand ➔ Kakkanad Infopark Express',
      'type': 'JanMarg Low-Floor City Bus',
    },
  ];

  Future<void> _handleConfirm() async {
    setState(() => _isSaving = true);
    await ref.read(conductorShiftProvider.notifier).pairBus(
      busNumber: _selectedBus,
      routeNumber: _selectedRoute,
      tripCode: 'TRIP-$_selectedBus-ACTIVE',
    );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle pairing confirmed: Bus $_selectedBus on Route $_selectedRoute'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Bus & Route Pairing', style: AppTypography.titleLarge),
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
            Text('Select Operational Vehicle', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pair your crew session with an active Kochi transit corridor bus.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Fleet Selection Cards
            ...kFleetOptions.map((opt) {
              final isSelected = opt['bus'] == _selectedBus;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedBus = opt['bus']!;
                    _selectedRoute = opt['route']!;
                  });
                },
                borderRadius: AppSpacing.roundedMd,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: isSelected ? AppColors.secondary : AppColors.border.withValues(alpha: 0.4),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_bus_rounded,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: AppSpacing.sm,
                              runSpacing: 4,
                              children: [
                                Text('BUS ${opt['bus']}', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                BusSenseStatusBadge(label: 'ROUTE ${opt['route']}', tone: BadgeTone.info),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(opt['corridor']!, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(opt['type']!, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.sm),

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
                      'SIMULATED ASSIGNMENT: Roster assignment synchronizes with local corridor simulation.',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Confirm Pairing Button
            BusSenseButton(
              label: _isSaving ? 'Confirming Pairing...' : 'Confirm Pairing',
              variant: ButtonVariant.primary,
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _handleConfirm,
            ),
          ],
        ),
      ),
    );
  }
}
