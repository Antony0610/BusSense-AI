import 'bus_model.dart';

/// Active Corridor Trip Model
class TripModel {
  final String tripId;
  final String tripCode;
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeNumber;
  final String currentStatus;
  final String currentStop;
  final String nextStop;
  final String startedAt;
  final String estimatedArrival;
  final double occupancyPct;
  final CrowdLevel crowdLevel;
  final String dataOrigin;

  const TripModel({
    required this.tripId,
    required this.tripCode,
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeNumber,
    required this.currentStatus,
    required this.currentStop,
    required this.nextStop,
    required this.startedAt,
    required this.estimatedArrival,
    required this.occupancyPct,
    required this.crowdLevel,
    this.dataOrigin = 'SIMULATED DATA',
  });

  String get id => tripId;
  String get status => currentStatus;
  int get delayMinutes => 4;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: json['trip_id'] as String? ?? json['id'] as String? ?? '',
      tripCode: json['trip_code'] as String? ?? '',
      busId: json['bus_id'] as String? ?? '',
      busNumber: json['bus_number'] as String? ?? '205',
      routeId: json['route_id'] as String? ?? '',
      routeNumber: json['route_number'] as String? ?? '12',
      currentStatus: json['current_status'] as String? ?? json['status'] as String? ?? 'IN_TRANSIT',
      currentStop: json['current_stop'] as String? ?? '',
      nextStop: json['next_stop'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
      estimatedArrival: json['estimated_arrival'] as String? ?? '',
      occupancyPct: (json['occupancy_pct'] as num?)?.toDouble() ?? 41.8,
      crowdLevel: CrowdLevel.fromString(json['crowd_level'] as String?),
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'trip_code': tripCode,
        'bus_id': busId,
        'bus_number': busNumber,
        'route_id': routeId,
        'route_number': routeNumber,
        'current_status': currentStatus,
        'current_stop': currentStop,
        'next_stop': nextStop,
        'started_at': startedAt,
        'estimated_arrival': estimatedArrival,
        'occupancy_pct': occupancyPct,
        'crowd_level': crowdLevel.value,
        'data_origin': dataOrigin,
      };
}
