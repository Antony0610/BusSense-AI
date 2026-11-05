import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/conductor_providers.dart';
import 'conductor_incident_screen.dart';

/// Conductor Tab 3: Operational Crew Alerts & Advisories
class ConductorAlertsView extends ConsumerWidget {
  const ConductorAlertsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(conductorAlertsProvider);
    final shift = ref.watch(conductorShiftProvider).valueOrNull;

    return alertsAsync.when(
      loading: () => const BusSenseLoading(message: 'Loading crew advisories...'),
      error: (err, st) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text('Failed to load crew alerts', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            BusSenseButton(
              label: 'Retry',
              variant: ButtonVariant.outline,
              onPressed: () => ref.refresh(conductorAlertsProvider),
            ),
          ],
        ),
      ),
      data: (alerts) {
        return ListView(
          padding: AppSpacing.paddingScreen,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('CREW DISPATCH ADVISORIES', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                BusSenseStatusBadge(label: '${alerts.length} ACTIVE', tone: BadgeTone.warning),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Alert Cards
            ...alerts.map((alert) {
              final isWarning = alert.severity == 'WARNING' || alert.severity == 'CRITICAL';
              final borderColor = isWarning ? AppColors.warning : AppColors.border.withValues(alpha: 0.4);
              final tone = isWarning ? BadgeTone.warning : BadgeTone.info;

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: borderColor, width: isWarning ? 1.5 : 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                          color: isWarning ? AppColors.warning : AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            alert.title,
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        BusSenseStatusBadge(label: alert.severity.toUpperCase(), tone: tone),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alert.message,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                    if (alert.affectedRoute.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Corridor: ${alert.affectedRoute}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
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
                      'SIMULATED ADVISORIES: Crew alerts represent simulated Greater Kochi corridor conditions.',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Report Incident Action
            BusSenseButton(
              label: 'Report New Incident / Hazard',
              variant: ButtonVariant.danger,
              icon: Icons.report_problem_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConductorIncidentScreen(
                      busNumber: shift?.busNumber ?? '205',
                      routeNumber: shift?.routeNumber ?? '12',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }
}
