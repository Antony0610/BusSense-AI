import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/bussense_empty_state.dart';
import '../../../shared/widgets/bussense_error_state.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'bus_details_screen.dart';
import 'passenger_live_map_view.dart';

/// Passenger Home View — Google Stitch Design System (Project 14259704318600090723)
/// Mirrors the official Stitch layout from frontend/app/passenger/home/page.tsx.
class PassengerHomeView extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onNavigateToExplore;

  const PassengerHomeView({
    super.key,
    required this.user,
    required this.onNavigateToExplore,
  });

  @override
  ConsumerState<PassengerHomeView> createState() => _PassengerHomeViewState();
}

class _PassengerHomeViewState extends ConsumerState<PassengerHomeView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showWhyDrawer = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(liveBusesProvider);
    final alertsAsync = ref.watch(activeAlertsProvider);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.secondary,
        backgroundColor: AppColors.white,
        onRefresh: () async {
          ref.invalidate(liveBusesProvider);
          ref.invalidate(activeAlertsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Chip & Greeting with Full Commuter Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 14, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Near Kaloor Metro Station, Kochi',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.user.fullName,
                                style: AppTypography.headlineLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                '$greeting • Daily Commuter',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live Map Action Button
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PassengerLiveMapView()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.map_rounded, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Live Map',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Hero Transit Search Bar
                    _buildStitchSearchBar(context),
                    const SizedBox(height: AppSpacing.xs),

                    // Quick Destination Pills (Infopark, Aluva, South, Fort Kochi)
                    _buildQuickDestinationPills(context),
                    const SizedBox(height: AppSpacing.sm),

                    // Active Service Alerts Banner (if any)
                    alertsAsync.when(
                      data: (alerts) {
                        if (alerts.isEmpty) return const SizedBox.shrink();
                        final alert = alerts.first;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildAlertBanner(context, alert.title, alert.message, alert.severity),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // Stitch Spotlight Card: Predictive Transit Insight
                    _buildPredictiveInsightCard(context),
                    const SizedBox(height: AppSpacing.md),

                    // Section Title: Live Departures Nearby
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Live Departures',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const BusSenseStatusBadge(
                              label: 'SIMULATED DATA',
                              tone: BadgeTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ),
              ),
            ),

            // Live Bus List Feed from Backend
            busesAsync.when(
              data: (buses) {
                if (buses.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: BusSenseEmptyState(
                      title: 'No Active Buses in Corridor',
                      message: 'No buses are currently reporting live telemetry on this corridor.',
                      icon: Icons.directions_bus_outlined,
                    ),
                  );
                }

                // Filter buses based on search if query entered
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? buses
                    : buses.where((b) {
                        return b.busNumber.toLowerCase().contains(query) ||
                            b.routeName.toLowerCase().contains(query) ||
                            b.nextStop.toLowerCase().contains(query);
                      }).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: BusSenseEmptyState(
                      title: 'No Matching Routes',
                      message: 'No departures matching "$query" found.',
                      icon: Icons.search_off_rounded,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bus = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: _buildStitchBusCard(context, bus),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: BusSenseLoading(message: 'Querying live corridor telemetry...'),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: BusSenseErrorState(
                  title: 'Telemetry Offline',
                  message: err.toString(),
                  onRetry: () => ref.refresh(liveBusesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyLarge.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Where are you going?',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice transit query: "Buses to Infopark"'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppColors.primaryContainer,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic_rounded, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDestinationPills(BuildContext context) {
    final destinations = [
      (dest: 'Infopark Phase 1', origin: 'Kaloor Metro Station, Kochi', icon: Icons.history_rounded),
      (dest: 'Ernakulam South Stand', origin: 'Kaloor Metro Station, Kochi', icon: Icons.train_rounded),
      (dest: 'Aluva Metro Station', origin: 'Kaloor Metro Station, Kochi', icon: Icons.subway_rounded),
      (dest: 'Fort Kochi Boat Jetty', origin: 'Kaloor Metro Station, Kochi', icon: Icons.directions_boat_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: destinations.map((d) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () {
                ref.read(journeyQueryProvider.notifier).state = JourneyQuery(
                  origin: d.origin,
                  destination: d.dest,
                );
                widget.onNavigateToExplore();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(d.icon, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Text(
                      d.dest,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictiveInsightCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PREDICTIVE TRANSIT INSIGHT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showWhyDrawer = !_showWhyDrawer),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Why?',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showWhyDrawer ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 15,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Main Insight Proposition (without breaking separate '205' finder)
          RichText(
            text: TextSpan(
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.white,
                fontSize: 14,
                height: 1.35,
              ),
              children: const [
                TextSpan(
                  text: 'Express Corridor: ',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent),
                ),
                TextSpan(text: 'Next scheduled departure offers '),
                TextSpan(
                  text: '40% lower crowd',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent),
                ),
                TextSpan(text: ' and saves 12 min on Banerji Road.'),
              ],
            ),
          ),

          // Expandable Rationalization Drawer
          if (_showWhyDrawer) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.alt_route_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fewer stops on Banerji Rd corridor',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bypasses Kaloor market signal congestion with dedicated priority lane timing.',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStitchBusCard(BuildContext context, BusModel bus) {
    final isLowCrowd = bus.crowdLevel == CrowdLevel.low;
    final isModerate = bus.crowdLevel == CrowdLevel.moderate;

    final crowdLabel = isLowCrowd
        ? 'Seats Available'
        : isModerate
            ? 'Standing Room'
            : 'At Capacity';

    final crowdColor = isLowCrowd
        ? AppColors.secondary
        : isModerate
            ? AppColors.warning
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(selectedBusProvider.notifier).state = bus;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BusDetailsScreen(bus: bus)),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Route Badge, Operator Type & ETA
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Number Emblem
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bus.busNumber,
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Service Type Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${bus.operatorType} ${bus.busNumber == "205" ? "Fast Passenger" : "City Feeder"}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Jitter-free Tabular ETA ("4 min", "9 min")
                    Text(
                      '${bus.etaNextStopMins} min',
                      style: AppTypography.tabularNumeral.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Middle Row: Next Stop Title & Corridor via
                Text(
                  bus.nextStop,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'via ${bus.routeName.contains("via") ? bus.routeName.split("via")[1].trim() : "Kaloor Corridor"}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Divider
                Container(height: 1, color: AppColors.border.withValues(alpha: 0.2)),
                const SizedBox(height: AppSpacing.xs),

                // Bottom Row: 3-Segment Occupancy Pill, Percent & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Segmented Occupancy Bar & %
                    Row(
                      children: [
                        Row(
                          children: [
                            _buildSegment(active: bus.occupancyPct > 0, color: AppColors.secondary),
                            const SizedBox(width: 3),
                            _buildSegment(active: bus.occupancyPct >= 50, color: AppColors.warning),
                            const SizedBox(width: 3),
                            _buildSegment(active: bus.occupancyPct > 80, color: AppColors.error),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${bus.occupancyPct.toStringAsFixed(0)}%',
                          style: AppTypography.tabularNumeral.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          crowdLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: crowdColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // AC / Non-AC & Operator
                    Row(
                      children: [
                        if (bus.isAc) ...[
                          const Icon(Icons.ac_unit_rounded, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          bus.registrationNumber,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({required bool active, required Color color}) {
    return Container(
      width: 14,
      height: 6,
      decoration: BoxDecoration(
        color: active ? color : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, String title, String message, String severity) {
    final isWarning = severity.toUpperCase() == 'WARNING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.warning.withValues(alpha: 0.1) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWarning ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: isWarning ? AppColors.warning : AppColors.secondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
