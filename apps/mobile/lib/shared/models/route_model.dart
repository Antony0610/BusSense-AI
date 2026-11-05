import 'stop_model.dart';

/// Corridor Transit Route
class RouteModel {
  final String id;
  final String routeNumber;
  final String routeName;
  final String corridorType;
  final String startStop;
  final String endStop;
  final double distanceKm;
  final int estimatedDurationMins;
  final String colorCode;
  final List<StopModel> stops;

  const RouteModel({
    required this.id,
    required this.routeNumber,
    required this.routeName,
    required this.corridorType,
    required this.startStop,
    required this.endStop,
    required this.distanceKm,
    required this.estimatedDurationMins,
    required this.colorCode,
    this.stops = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    var rawStops = json['stops'] as List<dynamic>? ?? [];
    List<StopModel> parsedStops = rawStops
        .map((s) => StopModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return RouteModel(
      id: json['id'] as String? ?? '',
      routeNumber: json['route_number'] as String? ?? '',
      routeName: json['route_name'] as String? ?? '',
      corridorType: json['corridor_type'] as String? ?? 'STAGE_CARRIAGE',
      startStop: json['start_stop'] as String? ?? '',
      endStop: json['end_stop'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMins: json['estimated_duration_mins'] as int? ?? 0,
      colorCode: json['color_code'] as String? ?? '#006c49',
      stops: parsedStops,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route_number': routeNumber,
        'route_name': routeName,
        'corridor_type': corridorType,
        'start_stop': startStop,
        'end_stop': endStop,
        'distance_km': distanceKm,
        'estimated_duration_mins': estimatedDurationMins,
        'color_code': colorCode,
        'stops': stops.map((s) => s.toJson()).toList(),
      };
}
