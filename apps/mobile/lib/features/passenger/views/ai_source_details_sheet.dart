import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/ai_message_model.dart';
import '../../../shared/widgets/bussense_status_badge.dart';

/// Modal bottom sheet presenting verified knowledge citations and live telemetry references
class AISourceDetailsSheet extends StatelessWidget {
  final List<AISourceItem> sourceItems;
  final List<String> fallbackSources;
  final String dataOrigin;

  const AISourceDetailsSheet({
    super.key,
    required this.sourceItems,
    this.fallbackSources = const [],
    this.dataOrigin = 'VERIFIED KNOWLEDGE BASE',
  });

  static Future<void> show(
    BuildContext context, {
    required List<AISourceItem> sourceItems,
    List<String> fallbackSources = const [],
    String dataOrigin = 'VERIFIED KNOWLEDGE BASE',
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AISourceDetailsSheet(
        sourceItems: sourceItems,
        fallbackSources: fallbackSources,
        dataOrigin: dataOrigin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Source Citations & Provenance', style: AppTypography.titleLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'BusSense AI Verified Information Trace',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: AppSpacing.paddingScreen,
              children: [
                // Provenance Classification Card
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.secondary, size: 22),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Data Origin & Provenance', style: AppTypography.titleMedium.copyWith(fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              dataOrigin,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const BusSenseStatusBadge(label: 'GROUNDED', tone: BadgeTone.success),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text('Retrieved Sources (${sourceItems.isNotEmpty ? sourceItems.length : fallbackSources.length})', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),

                if (sourceItems.isNotEmpty)
                  ...sourceItems.map((item) => _buildSourceCard(item))
                else if (fallbackSources.isNotEmpty)
                  ...fallbackSources.map((src) => _buildFallbackSourceCard(src))
                else
                  Padding(
                    padding: AppSpacing.paddingLg,
                    child: Center(
                      child: Text(
                        'No additional source citations attached.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.md),

                // Transparency Disclaimer
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'BusSense AI cross-references verified static transit protocols with live GPS and occupancy telemetry. Out-of-domain queries are declined to prevent hallucinations.',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCard(AISourceItem item) {
    final tone = switch (item.sourceType.toUpperCase()) {
      'LIVE_DATA' => BadgeTone.success,
      'PREDICTION' => BadgeTone.warning,
      'RECOMMENDATION' => BadgeTone.neutral,
      'TICKET_DATA' => BadgeTone.neutral,
      _ => BadgeTone.neutral,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              BusSenseStatusBadge(label: item.sourceType, tone: tone),
            ],
          ),
          if (item.snippet != null && item.snippet!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.paddingSm,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.roundedSm,
                border: Border(left: BorderSide(color: AppColors.secondary, width: 3)),
              ),
              child: Text(
                '"${item.snippet!}"',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (item.reference != null && item.reference!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.link_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.reference!,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackSourceCard(String src) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 18, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              src,
              style: AppTypography.titleMedium.copyWith(fontSize: 13),
            ),
          ),
          const BusSenseStatusBadge(label: 'VERIFIED', tone: BadgeTone.neutral),
        ],
      ),
    );
  }
}
