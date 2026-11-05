import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/bussense_button.dart';
import 'report_issue_screen.dart';

/// Screen presenting grounded transit FAQs and in-app support reporting
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<Map<String, String>> faqs = [
    {
      'question': 'How is cabin crowd level calculated?',
      'answer':
          'BusSense AI estimates onboard crowding using a privacy-preserving YOLOv8 neural network. The model counts heads and upper-body silhouettes to compute cabin density:\n\n• Low (<45%): Ample seating available\n• Moderate (45–75%): Few seats, comfortable standing\n• Crowded (>75%): Heavy occupancy, standing only\n\nThe system strictly does NOT perform facial recognition, demographic profiling, or passenger tracking.'
    },
    {
      'question': 'Why did BusSense recommend this bus?',
      'answer':
          'BusSense uses a multi-factor optimization engine to rank alternative buses along your corridor:\n\n• 40% Cabin Crowding: Steers commuters away from packed buses\n• 35% Corridor Duration: Rewards dedicated lanes and metro feeder links\n• 15% Historical Punctuality: Prefers consistent schedules\n• 10% Fare Efficiency: Transparent stage carriage tariffs'
    },
    {
      'question': 'How does the digital QR boarding pass work?',
      'answer':
          'Tickets follow standard Kerala stage-carriage transit rules (unassigned seating). Once booked, a cryptographically signed QR token is displayed. On boarding, the conductor scans your pass with the BusSense Conductor Cockpit to validate entry and prevent duplicate reuse.'
    },
    {
      'question': 'Why can bus ETA change dynamically?',
      'answer':
          'ETAs are continuously calculated using live GPS transponder speed and position along primary Kochi corridors (Aluva, Edappally, Banerji Road, Vyttila Hub). Heavy intersection delays or priority lane movements dynamically update arrival countdowns.'
    },
    {
      'question': 'What can the BusSense AI Assistant answer?',
      'answer':
          'The transit assistant is grounded strictly on Greater Kochi transit corridors, real-time vehicle GPS telemetry, and your active boarding passes. It will decline out-of-domain questions (such as world trivia or financial advice) to prevent AI hallucinations.'
    },
    {
      'question': 'Why does the app show SIMULATED DATA badges?',
      'answer':
          'Truth labeling is a core BusSense principle. When hardware vehicle transponders or real payment gateways are not active in development environments, data is honestly labeled as SIMULATED DATA or PREDICTION rather than pretending it is live production telemetry.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Help & FAQ', style: AppTypography.titleLarge),
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
            Text(
              'Frequently Asked Questions',
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reliable transit answers grounded in verified BusSense architecture.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // FAQ Accordion Cards
            ...faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Material(
                  color: AppColors.white,
                  borderRadius: AppSpacing.roundedSm,
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                      childrenPadding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.md),
                      iconColor: AppColors.secondary,
                      collapsedIconColor: AppColors.textSecondary,
                      title: Text(
                        faq['question']!,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        Text(
                          faq['answer']!,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // Report an Issue CTA
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
                    children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.accent, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Still have an issue?',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Encountered a delayed bus, faulty AC, or inaccurate crowd prediction? Submit a direct transit report to our operations team.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.85), height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BusSenseButton(
                    label: 'Report an Issue',
                    variant: ButtonVariant.primary,
                    icon: Icons.report_problem_outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                      );
                    },
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
