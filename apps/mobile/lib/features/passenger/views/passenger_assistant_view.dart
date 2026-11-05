import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/ai_message_model.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'active_journey_screen.dart';
import 'ai_source_details_sheet.dart';
import 'bus_details_screen.dart';
import 'crowd_forecast_screen.dart';
import 'digital_qr_ticket_screen.dart';
import 'passenger_explore_view.dart';

/// Primary Passenger AI Transit Assistant View
class PassengerAssistantView extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onNavigateToTickets;

  const PassengerAssistantView({
    super.key,
    this.onNavigateToExplore,
    this.onNavigateToTickets,
  });

  @override
  ConsumerState<PassengerAssistantView> createState() => _PassengerAssistantViewState();
}

class _PassengerAssistantViewState extends ConsumerState<PassengerAssistantView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _canSend) {
        setState(() => _canSend = hasText);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitQuery(String query) {
    if (query.trim().isEmpty) return;
    final activeTicket = ref.read(activeTicketProvider);
    final activeBus = activeTicket?.busNumber;
    final destination = activeTicket?.destinationStop;

    ref.read(aiMessagesProvider.notifier).sendQuery(
          query,
          activeBus: activeBus,
          destination: destination,
          ticketId: activeTicket?.id,
        );

    _textController.clear();
    _scrollToBottom();
  }

  void _handleAction(AIActionItem action) {
    final activeTicket = ref.read(activeTicketProvider);

    switch (action.actionType) {
      case 'SHOW_TICKET':
        if (activeTicket != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DigitalQrTicketScreen(ticket: activeTicket)),
          );
        } else if (widget.onNavigateToTickets != null) {
          widget.onNavigateToTickets!();
        }
        break;

      case 'TRACK_HUD':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ActiveJourneyScreen(ticket: activeTicket)),
        );
        break;

      case 'VIEW_BUS':
        final busNumber = action.payload?['bus_number'] as String? ?? '205';
        final buses = ref.read(liveBusesProvider).valueOrNull ?? [];
        BusModel? targetBus;
        for (final b in buses) {
          if (b.busNumber == busNumber) {
            targetBus = b;
            break;
          }
        }
        targetBus ??= buses.isNotEmpty ? buses.first : null;
        if (targetBus != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BusDetailsScreen(bus: targetBus!)),
          );
        }
        break;

      case 'CROWD_FORECAST':
        final busNumber = action.payload?['bus_number'] as String? ?? '205';
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CrowdForecastScreen(busNumber: busNumber)),
        );
        break;

      case 'EXPLORE_ROUTES':
        if (widget.onNavigateToExplore != null) {
          widget.onNavigateToExplore!();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Scaffold(body: PassengerExploreView())),
          );
        }
        break;

      case 'ASK_QUERY':
        final query = action.payload?['query'] as String?;
        if (query != null && query.isNotEmpty) {
          _submitQuery(query);
        }
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiMessagesProvider);
    final isLoading = ref.watch(aiLoadingProvider);
    final suggestedPrompts = ref.watch(suggestedPromptsProvider);
    final activeTicket = ref.watch(activeTicketProvider);

    // Auto-scroll on new messages
    ref.listen(aiMessagesProvider, (prev, next) {
      if (next.length != prev?.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Assistant Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.psychology_rounded, color: AppColors.accent, size: 18),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text('BusSense AI', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your journey assistant',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const BusSenseStatusBadge(label: 'RAG GROUNDED', tone: BadgeTone.success),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton(
                        tooltip: 'Reset Conversation',
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                        onPressed: () => ref.read(aiMessagesProvider.notifier).resetConversation(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active Journey / Ticket Context Bar (if present)
            if (activeTicket != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus_rounded, size: 16, color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Active Context: Bus ${activeTicket.busNumber} ➔ ${activeTicket.destinationStop}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _submitQuery('When will I reach ${activeTicket.destinationStop}?'),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Ask ETA',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _submitQuery('What is my next stop?'),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Next Stop',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Message Stream Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: AppSpacing.paddingScreen,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _buildMessageItem(context, msg);
                },
              ),
            ),

            // Subtle Typing Indicator
            if (isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Retrieving verified corridor intelligence...',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Suggested Starter Prompts Carousel
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: suggestedPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final prompt = suggestedPrompts[index];
                  return ActionChip(
                    label: Text(
                      prompt,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                    ),
                    backgroundColor: AppColors.white,
                    side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: isLoading ? null : () => _submitQuery(prompt),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.35))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _textController,
                      style: AppTypography.bodyLarge,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (val) => _submitQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Ask about your journey...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: _canSend && !isLoading ? AppColors.primary : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: _canSend && !isLoading ? AppColors.white : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: !isLoading ? () => _submitQuery(_textController.text) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessage msg) {
    if (msg.isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.radiusMd),
              topRight: Radius.circular(AppSpacing.radiusMd),
              bottomLeft: Radius.circular(AppSpacing.radiusMd),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.white),
          ),
        ),
      );
    }

    // Assistant Message Card
    final badgeTone = switch (msg.responseType) {
      AIResponseType.liveData => BadgeTone.success,
      AIResponseType.prediction => BadgeTone.warning,
      AIResponseType.recommendation => BadgeTone.neutral,
      AIResponseType.ticketData => BadgeTone.neutral,
      AIResponseType.activeJourney => BadgeTone.success,
      AIResponseType.insufficientInformation => BadgeTone.error,
      AIResponseType.knowledge => BadgeTone.neutral,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusMd),
            topRight: Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(AppSpacing.radiusMd),
          ),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Classification & Provenance Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BusSenseStatusBadge(label: msg.responseType.label, tone: badgeTone),
                Text(
                  msg.dataOrigin,
                  style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Answer Content
            Text(
              msg.text,
              style: AppTypography.bodyLarge.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),

            // Sources / Citations Button
            if (msg.sourceItems.isNotEmpty || msg.sources.isNotEmpty) ...[
              Wrap(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      AISourceDetailsSheet.show(
                        context,
                        sourceItems: msg.sourceItems,
                        fallbackSources: msg.sources,
                        dataOrigin: msg.dataOrigin,
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.secondary),
                    label: Text(
                      '${msg.sourceItems.isNotEmpty ? msg.sourceItems.length : msg.sources.length} Verified Sources',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                      side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Action Deep-Links
            if (msg.actions.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: msg.actions.map((act) {
                  return BusSenseButton(
                    label: act.label,
                    icon: _actionIcon(act.actionType),
                    variant: ButtonVariant.outline,
                    onPressed: () => _handleAction(act),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _actionIcon(String actionType) {
    switch (actionType) {
      case 'SHOW_TICKET':
        return Icons.confirmation_number_outlined;
      case 'TRACK_HUD':
        return Icons.navigation_rounded;
      case 'VIEW_BUS':
        return Icons.directions_bus_rounded;
      case 'CROWD_FORECAST':
        return Icons.insights_rounded;
      case 'EXPLORE_ROUTES':
        return Icons.alt_route_rounded;
      case 'ASK_QUERY':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }
}
