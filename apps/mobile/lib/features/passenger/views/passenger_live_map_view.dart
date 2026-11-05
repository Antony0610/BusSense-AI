import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/widgets/bussense_button.dart';
import '../../../shared/widgets/bussense_error_state.dart';
import '../../../shared/widgets/bussense_loading.dart';
import '../../../shared/widgets/bussense_status_badge.dart';
import '../providers/passenger_providers.dart';
import 'bus_details_screen.dart';

/// Passenger Live Corridor Map with OpenStreetMap & Simulated Telemetry
class PassengerLiveMapView extends ConsumerStatefulWidget {
  const PassengerLiveMapView({super.key});

  @override
  ConsumerState<PassengerLiveMapView> createState() => _PassengerLiveMapViewState();
}

class _PassengerLiveMapViewState extends ConsumerState<PassengerLiveMapView> {
  late final MapController _mapController;
  BusModel? _selectedBus;

  // Kochi Transit Corridor Central Coordinate
  static const LatLng _kochiCenter = LatLng(9.9816, 76.3031);

  // Key Kochi Corridor Polyline Points (Aluva -> Edappally -> Kaloor -> Vyttila)
  static const List<LatLng> _corridorWaypoints = [
    LatLng(10.1076, 76.3516), // Aluva Metro
    LatLng(10.0533, 76.3218), // Kalamassery Premier
    LatLng(10.0236, 76.3083), // Edappally Toll
    LatLng(9.9984, 76.3025),  // Palarivattom Jn
    LatLng(9.9816, 76.3031),  // Kaloor Metro
    LatLng(9.9723, 76.2842),  // MG Road
    LatLng(9.9678, 76.2989),  // Kadavanthra Jn
    LatLng(9.9691, 76.3182),  // Vyttila Mobility Hub
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedBus = ref.read(selectedBusProvider);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    _mapController.move(_kochiCenter, 12.5);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(liveBusesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Fleet Map', style: AppTypography.titleLarge),
            Text('Kochi Transit Corridor • OpenStreetMap', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Vehicle Telemetry',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
            onPressed: () => ref.refresh(liveBusesProvider),
          ),
        ],
      ),
      body: busesAsync.when(
        data: (buses) => Stack(
          children: [
            // Map Canvas
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedBus != null
                    ? LatLng(_selectedBus!.latitude, _selectedBus!.longitude)
                    : _kochiCenter,
                initialZoom: 12.5,
                minZoom: 9.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bussense.ai',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _corridorWaypoints,
                      color: AppColors.secondary.withValues(alpha: 0.65),
                      strokeWidth: 4.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: buses.map((bus) {
                    final isSelected = _selectedBus?.busNumber == bus.busNumber;
                    return Marker(
                      point: LatLng(bus.latitude, bus.longitude),
                      width: 54,
                      height: 54,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedBus = bus);
                          ref.read(selectedBusProvider.notifier).state = bus;
                          _mapController.move(LatLng(bus.latitude, bus.longitude), 14.0);
                        },
                        child: _buildBusMarker(bus, isSelected),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Top Status Bar: Honest Telemetry Pill
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.95),
                  borderRadius: AppSpacing.roundedFull,
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Consumer(
                  builder: (context, ref, _) {
                    final freshness = ref.watch(telemetryFreshnessProvider);
                    final isStale = ref.watch(telemetryIsStaleProvider);
                    final statusColor = isStale ? AppColors.warning : AppColors.secondary;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sensors_rounded, size: 14, color: statusColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'SIMULATED GPS TELEMETRY • $freshness',
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Map Controls (Right Side)
            Positioned(
              right: AppSpacing.md,
              bottom: _selectedBus != null ? 220 : AppSpacing.xl,
              child: Column(
                children: [
                  _buildMapControlButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Zoom In',
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildMapControlButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Zoom Out',
                    onPressed: _zoomOut,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildMapControlButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Recenter Corridor',
                    onPressed: _recenterMap,
                  ),
                ],
              ),
            ),

            // Selected Bus Bottom Sheet Card
            if (_selectedBus != null)
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.lg,
                child: _buildSelectedBusCard(_selectedBus!),
              ),
          ],
        ),
        loading: () => const BusSenseLoading(message: 'Connecting to corridor vehicle telemetry...'),
        error: (err, _) => BusSenseErrorState(
          title: 'Unable to Load Live Map',
          message: err.toString(),
          onRetry: () => ref.refresh(liveBusesProvider),
        ),
      ),
    );
  }

  Widget _buildBusMarker(BusModel bus, bool isSelected) {
    final crowdColor = switch (bus.crowdLevel) {
      CrowdLevel.low => AppColors.crowdLow,
      CrowdLevel.moderate => AppColors.crowdModerate,
      CrowdLevel.crowded => AppColors.crowdHigh,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.xxs + 1),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: crowdColor,
          width: isSelected ? 3.0 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: crowdColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 16,
              color: crowdColor,
            ),
            Text(
              bus.busNumber,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSelectedBusCard(BusModel bus) {
    final crowdTone = switch (bus.crowdLevel) {
      CrowdLevel.low => BadgeTone.success,
      CrowdLevel.moderate => BadgeTone.warning,
      CrowdLevel.crowded => BadgeTone.error,
    };

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Text(
                  bus.busNumber,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.routeName, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Next: ${bus.nextStop}', style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => setState(() => _selectedBus = null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BusSenseStatusBadge(label: bus.crowdLevel.value, tone: crowdTone),
              Text(
                '${bus.occupancyPct.toStringAsFixed(0)}% Occupied',
                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Speed: ${bus.speedKmh.toStringAsFixed(0)} km/h',
                style: AppTypography.labelSmall,
              ),
              Text(
                'ETA: ${bus.etaNextStopMins} min',
                style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BusSenseButton(
            label: 'View Bus Details & Forecast',
            icon: Icons.info_outline_rounded,
            variant: ButtonVariant.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BusDetailsScreen(bus: bus)),
              );
            },
          ),
        ],
      ),
    );
  }
}
