import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/config/env_config.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_logo.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../passenger/providers/passenger_providers.dart';

/// Transport Authority Mobile Monitor Screen — Google Stitch Design System
/// Provides real-time fleet overview, corridor load, and incident surveillance
/// for Authority personnel on mobile devices.
class AuthorityOverviewScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const AuthorityOverviewScreen({super.key, required this.user});

  @override
  ConsumerState<AuthorityOverviewScreen> createState() => _AuthorityOverviewScreenState();
}

class _AuthorityOverviewScreenState extends ConsumerState<AuthorityOverviewScreen> {
  void _copyPortalUrl() {
    Clipboard.setData(ClipboardData(text: EnvConfig.authorityPortalUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Portal link copied: ${EnvConfig.authorityPortalUrl}'),
        backgroundColor: AppColors.primaryContainer,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(liveBusesProvider);
    final alertsAsync = ref.watch(activeAlertsProvider);

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
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'AUTHORITY COMMAND MONITOR',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.warning,
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
                      'AUTHORITY',
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
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () async {
          ref.invalidate(liveBusesProvider);
          ref.invalidate(activeAlertsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Welcoming Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        widget.user.fullName.isNotEmpty ? widget.user.fullName[0].toUpperCase() : 'A',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.user.fullName, style: AppTypography.titleMedium),
                          Text('KSRTC Command & Control • Dispatch Authority', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    const BusSenseStatusBadge(label: 'ONLINE', tone: BadgeTone.success),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // KPI Grid (Stitch 2x2 cards)
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'ACTIVE FLEET',
                      value: '28 / 32',
                      subtitle: '87.5% in service',
                      color: AppColors.secondary,
                      icon: Icons.directions_bus_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'ON-TIME RATE',
                      value: '94.2%',
                      subtitle: '+2.1% vs target',
                      color: AppColors.primary,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      title: 'PEAK DEMAND',
                      value: '1,240/hr',
                      subtitle: 'Kaloor corridor',
                      color: AppColors.warning,
                      icon: Icons.groups_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildKpiCard(
                      title: 'SAFETY SCORE',
                      value: '99.4%',
                      subtitle: '0 critical incidents',
                      color: AppColors.secondary,
                      icon: Icons.shield_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Web Console Link Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.laptop_chromebook_rounded, color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Authority Web Portal Required',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Welcome, ${widget.user.fullName}. Transport Authority command and fleet dispatch features are restricted to the web console.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Access URL: ${EnvConfig.authorityPortalUrl}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BusSenseButton(
                      label: 'Copy Portal URL to Clipboard',
                      icon: Icons.copy_rounded,
                      variant: ButtonVariant.secondary,
                      onPressed: _copyPortalUrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Corridors Status
              Text(
                'CORRIDOR SURVEILLANCE',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              _buildCorridorRow(
                corridor: 'Aluva Metro ➔ Vyttila Hub via Kaloor',
                routeNum: '205',
                busesCount: 14,
                status: 'OPTIMAL FLOW',
                tone: BadgeTone.success,
              ),
              const SizedBox(height: 6),
              _buildCorridorRow(
                corridor: 'Fort Kochi Stand ➔ Infopark Phase 1',
                routeNum: '14A',
                busesCount: 8,
                status: 'MODERATE LOAD',
                tone: BadgeTone.warning,
              ),
              const SizedBox(height: 6),
              _buildCorridorRow(
                corridor: 'Menaka Marine Drive ➔ Kakkanad Stand',
                routeNum: '33B',
                busesCount: 6,
                status: 'ON SCHEDULE',
                tone: BadgeTone.neutral,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Switch Account Action
              Center(
                child: TextButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.primary),
                  label: Text(
                    'Switch Account / Return to Login',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.tabularNumeral.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorRow({
    required String corridor,
    required String routeNum,
    required int busesCount,
    required String status,
    required BadgeTone tone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              routeNum,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  corridor,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$busesCount buses operational',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          BusSenseStatusBadge(label: status, tone: tone),
        ],
      ),
    );
  }
}
