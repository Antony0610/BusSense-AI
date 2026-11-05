/// Standard Crowd Level Thresholds
enum CrowdLevel {
  low('LOW'),
  moderate('MODERATE'),
  crowded('CROWDED');

  final String value;
  const CrowdLevel(this.value);

  static CrowdLevel fromString(String? level) {
    switch (level?.toUpperCase()) {
      case 'CROWDED':
      case 'HIGH':
        return CrowdLevel.crowded;
      case 'MODERATE':
      case 'MEDIUM':
        return CrowdLevel.moderate;
      case 'LOW':
      default:
        return CrowdLevel.low;
    }
  }
}

/// Shared Bus Model supporting both Passenger and Conductor workflows
class BusModel {
  final String busId;
  final String busNumber;
  final String registrationNumber;
  final String operatorType;
  final String routeNumber;
  final String routeName;
  final int capacity;
  final int passengerCount;
  final double occupancyPct;
  final CrowdLevel crowdLevel;
  final double speedKmh;
  final double headingDeg;
  final double latitude;
  final double longitude;
  final String currentStop;
  final String nextStop;
  final int etaNextStopMins;
  final bool isAc;
  final double safetyScore;
  final String dataOrigin;

  const BusModel({
    required this.busId,
    required this.busNumber,
    required this.registrationNumber,
    required this.operatorType,
    required this.routeNumber,
    required this.routeName,
    required this.capacity,
    required this.passengerCount,
    required this.occupancyPct,
    required this.crowdLevel,
    required this.speedKmh,
    required this.headingDeg,
    required this.latitude,
    required this.longitude,
    required this.currentStop,
    required this.nextStop,
    required this.etaNextStopMins,
    this.isAc = false,
    this.safetyScore = 98.5,
    this.dataOrigin = 'SIMULATED DATA',
  });

  int get currentOccupancy => passengerCount;
  double get occupancyPercentage => occupancyPct;

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busId: json['bus_id'] as String? ?? json['id'] as String? ?? '',
      busNumber: json['bus_number'] as String? ?? '205',
      registrationNumber: json['registration_number'] as String? ?? 'KL-15-A-2051',
      operatorType: json['operator_type'] as String? ?? 'KSRTC',
      routeNumber: json['route_number'] as String? ?? '12',
      routeName: json['route_name'] as String? ?? 'Aluva - Vyttila Hub',
      capacity: json['capacity'] as int? ?? json['total_capacity'] as int? ?? 55,
      passengerCount: json['passenger_count'] as int? ?? json['current_occupancy'] as int? ?? 23,
      occupancyPct: (json['occupancy_pct'] as num?)?.toDouble() ??
          (json['occupancy_percentage'] as num?)?.toDouble() ??
          (((json['passenger_count'] as int? ?? json['current_occupancy'] as int? ?? 23) /
                  (json['capacity'] as int? ?? json['total_capacity'] as int? ?? 55)) *
              100.0),
      crowdLevel: CrowdLevel.fromString(json['crowd_level'] as String?),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 34.0,
      headingDeg: (json['heading_deg'] as num?)?.toDouble() ?? 195.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 9.9984,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 76.3025,
      currentStop: json['current_stop'] as String? ?? 'Palarivattom Jn',
      nextStop: json['next_stop'] as String? ?? 'Kaloor Central Stand',
      etaNextStopMins: json['eta_next_stop_mins'] as int? ?? 4,
      isAc: json['is_ac'] as bool? ?? false,
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 98.5,
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'bus_id': busId,
        'bus_number': busNumber,
        'registration_number': registrationNumber,
        'operator_type': operatorType,
        'route_number': routeNumber,
        'route_name': routeName,
        'capacity': capacity,
        'passenger_count': passengerCount,
        'occupancy_pct': occupancyPct,
        'crowd_level': crowdLevel.value,
        'speed_kmh': speedKmh,
        'heading_deg': headingDeg,
        'latitude': latitude,
        'longitude': longitude,
        'current_stop': currentStop,
        'next_stop': nextStop,
        'eta_next_stop_mins': etaNextStopMins,
        'is_ac': isAc,
        'safety_score': safetyScore,
        'data_origin': dataOrigin,
      };
}
