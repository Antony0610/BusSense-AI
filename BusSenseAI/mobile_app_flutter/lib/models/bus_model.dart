class BusModel {
  final String busId;
  final String operatorType; // 'KSRTC' or 'PRIVATE'
  final String routeNumber;
  final int capacity;
  final int passengerCount;
  final double occupancyPercentage;
  final int seatAvailability;
  final double latitude;
  final double longitude;
  final int etaMinutes;
  final String crowdLevel; // 'Green', 'Yellow', 'Red'
  final double busUtilizationScore;

  BusModel({
    required this.busId,
    required this.operatorType,
    required this.routeNumber,
    required this.capacity,
    required this.passengerCount,
    required this.occupancyPercentage,
    required this.seatAvailability,
    required this.latitude,
    required this.longitude,
    required this.etaMinutes,
    required this.crowdLevel,
    required this.busUtilizationScore,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busId: json['bus_id'] ?? 'KSRTC-101',
      operatorType: json['operator_type'] ?? 'KSRTC',
      routeNumber: json['route_number'] ?? 'R1',
      capacity: json['capacity'] ?? 50,
      passengerCount: json['passenger_count'] ?? 0,
      occupancyPercentage: (json['occupancy_percentage'] as num?)?.toDouble() ?? 0.0,
      seatAvailability: json['seat_availability'] ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 8.5241,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 76.9366,
      etaMinutes: json['eta_minutes'] ?? 5,
      crowdLevel: json['crowd_level'] ?? 'Green',
      busUtilizationScore: (json['bus_utilization_score'] as num?)?.toDouble() ?? 50.0,
    );
  }

  int get seatProbability {
    final total = passengerCount + seatAvailability;
    if (total == 0) return 50;
    return ((seatAvailability / total) * 100).round().clamp(5, 98);
  }

  int get comfortScore {
    final occFactor = (100 - occupancyPercentage) * 0.65;
    final seatFactor = (seatAvailability.clamp(0, 25)) * 1.4;
    final etaFactor = (15 - etaMinutes).clamp(0, 15).toDouble();
    return (occFactor + seatFactor + etaFactor).round().clamp(0, 100);
  }

  int get overcrowd15MinRisk {
    return (occupancyPercentage + ((15 - etaMinutes.clamp(0, 15)) * 1.5)).round().clamp(0, 100);
  }
}
