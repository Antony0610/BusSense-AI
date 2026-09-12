class BusModel {
  final String busId;
  final String operatorType; // 'KSRTC_SUPERFAST', 'KSRTC_SWIFT', 'PRIVATE'
  final String routeNumber;
  final String routeName;
  final String routeNameMl;
  final int capacity;
  final int passengerCount;
  final double occupancyPercentage;
  final int seatAvailability;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final int etaMinutes;
  final String crowdLevel;
  final double co2ReductionKg;

  BusModel({
    required this.busId,
    required this.operatorType,
    required this.routeNumber,
    required this.routeName,
    required this.routeNameMl,
    required this.capacity,
    required this.passengerCount,
    required this.occupancyPercentage,
    required this.seatAvailability,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.etaMinutes,
    required this.crowdLevel,
    required this.co2ReductionKg,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busId: json['bus_id']?.toString() ?? '',
      operatorType: json['operator_type']?.toString() ?? 'KSRTC_SUPERFAST',
      routeNumber: json['route_number']?.toString() ?? 'R1',
      routeName: json['route_name']?.toString() ?? 'Thampanoor ➔ Technopark',
      routeNameMl: json['route_name_ml']?.toString() ?? 'തമ്പാനൂർ ➔ ടെക്നോപാർക്ക്',
      capacity: json['capacity'] is int ? json['capacity'] : (int.tryParse(json['capacity']?.toString() ?? '50') ?? 50),
      passengerCount: json['passenger_count'] is int ? json['passenger_count'] : (int.tryParse(json['passenger_count']?.toString() ?? '20') ?? 20),
      occupancyPercentage: (json['occupancy_percentage'] as num?)?.toDouble() ?? 40.0,
      seatAvailability: json['seat_availability'] is int ? json['seat_availability'] : (int.tryParse(json['seat_availability']?.toString() ?? '30') ?? 30),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 8.5241,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 76.9366,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 35.0,
      etaMinutes: json['eta_minutes'] is int ? json['eta_minutes'] : (int.tryParse(json['eta_minutes']?.toString() ?? '5') ?? 5),
      crowdLevel: json['crowd_level']?.toString() ?? 'Green',
      co2ReductionKg: (json['co2_reduction_kg'] as num?)?.toDouble() ?? 24.5,
    );
  }
}

class TicketModel {
  final String ticketId;
  final String userId;
  final String busId;
  final String routeNumber;
  final String seatNumber;
  final String originStop;
  final String destinationStop;
  final double fareAmount;
  final String qrCodeHash;

  TicketModel({
    required this.ticketId,
    required this.userId,
    required this.busId,
    required this.routeNumber,
    required this.seatNumber,
    required this.originStop,
    required this.destinationStop,
    required this.fareAmount,
    required this.qrCodeHash,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      ticketId: json['ticket_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      busId: json['bus_id']?.toString() ?? '',
      routeNumber: json['route_number']?.toString() ?? '',
      seatNumber: json['seat_number']?.toString() ?? '',
      originStop: json['origin_stop']?.toString() ?? '',
      destinationStop: json['destination_stop']?.toString() ?? '',
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 32.0,
      qrCodeHash: json['qr_code_hash']?.toString() ?? 'BUSSENSE-SECURE-TICKET',
    );
  }
}

class SOSAlertModel {
  final String sosId;
  final String busId;
  final String routeNumber;
  final double latitude;
  final double longitude;
  final String status;
  final String timestamp;

  SOSAlertModel({
    required this.sosId,
    required this.busId,
    required this.routeNumber,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.timestamp,
  });

  factory SOSAlertModel.fromJson(Map<String, dynamic> json) {
    return SOSAlertModel(
      sosId: json['sos_id']?.toString() ?? '',
      busId: json['bus_id']?.toString() ?? '',
      routeNumber: json['route_number']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 8.5241,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 76.9366,
      status: json['status']?.toString() ?? 'active',
      timestamp: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
