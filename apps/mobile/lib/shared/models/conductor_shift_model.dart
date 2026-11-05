/// Conductor / Driver Operational Shift & Trip Lifecycle Models
class ConductorTripModel {
  final String tripId;
  final String tripCode;
  final String busNumber;
  final String routeNumber;
  final String origin;
  final String destination;
  final String currentStop;
  final String nextStop;
  final String status; // 'NOT_STARTED', 'ACTIVE', 'COMPLETED'
  final double occupancyPct;
  final String crowdLevel;
  final int etaMinutes;
  final double progressPct;
  final double speedKmh;

  const ConductorTripModel({
    required this.tripId,
    required this.tripCode,
    required this.busNumber,
    required this.routeNumber,
    required this.origin,
    required this.destination,
    required this.currentStop,
    required this.nextStop,
    this.status = 'ACTIVE',
    this.occupancyPct = 41.8,
    this.crowdLevel = 'LOW',
    this.etaMinutes = 6,
    this.progressPct = 0.65,
    this.speedKmh = 28.5,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';

  factory ConductorTripModel.fromJson(Map<String, dynamic> json) {
    return ConductorTripModel(
      tripId: json['trip_id'] as String? ?? 'trip-sim-205',
      tripCode: json['trip_code'] as String? ?? 'TRIP-205-ACTIVE',
      busNumber: json['bus_number'] as String? ?? '205',
      routeNumber: json['route_number'] as String? ?? '12',
      origin: json['origin'] as String? ?? 'Aluva Metro Station',
      destination: json['destination'] as String? ?? 'Vyttila Mobility Hub',
      currentStop: json['current_stop'] as String? ?? 'Palarivattom Jn',
      nextStop: json['next_stop'] as String? ?? 'Kaloor Central Stand',
      status: json['status'] as String? ?? 'ACTIVE',
      occupancyPct: (json['occupancy_pct'] as num?)?.toDouble() ?? 41.8,
      crowdLevel: json['crowd_level'] as String? ?? 'LOW',
      etaMinutes: json['eta_minutes'] as int? ?? 6,
      progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0.65,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 28.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'trip_code': tripCode,
        'bus_number': busNumber,
        'route_number': routeNumber,
        'origin': origin,
        'destination': destination,
        'current_stop': currentStop,
        'next_stop': nextStop,
        'status': status,
        'occupancy_pct': occupancyPct,
        'crowd_level': crowdLevel,
        'eta_minutes': etaMinutes,
        'progress_pct': progressPct,
        'speed_kmh': speedKmh,
      };

  ConductorTripModel copyWith({
    String? tripId,
    String? tripCode,
    String? busNumber,
    String? routeNumber,
    String? origin,
    String? destination,
    String? currentStop,
    String? nextStop,
    String? status,
    double? occupancyPct,
    String? crowdLevel,
    int? etaMinutes,
    double? progressPct,
    double? speedKmh,
  }) {
    return ConductorTripModel(
      tripId: tripId ?? this.tripId,
      tripCode: tripCode ?? this.tripCode,
      busNumber: busNumber ?? this.busNumber,
      routeNumber: routeNumber ?? this.routeNumber,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      currentStop: currentStop ?? this.currentStop,
      nextStop: nextStop ?? this.nextStop,
      status: status ?? this.status,
      occupancyPct: occupancyPct ?? this.occupancyPct,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      progressPct: progressPct ?? this.progressPct,
      speedKmh: speedKmh ?? this.speedKmh,
    );
  }
}

class ConductorShiftModel {
  final String dutyId;
  final String staffName;
  final String staffId;
  final String role;
  final String status; // 'CHECKED_IN', 'NOT_CHECKED_IN'
  final String pairingStatus; // 'PAIRED', 'UNPAIRED'
  final String busNumber;
  final String routeNumber;
  final String shiftName;
  final String shiftHours;
  final ConductorTripModel? activeTrip;
  final String? checkInTime;
  final String dataOrigin;

  const ConductorShiftModel({
    required this.dutyId,
    required this.staffName,
    required this.staffId,
    this.role = 'DRIVER_CONDUCTOR',
    this.status = 'CHECKED_IN',
    this.pairingStatus = 'PAIRED',
    this.busNumber = '205',
    this.routeNumber = '12',
    this.shiftName = 'Morning Peak Corridor Shift',
    this.shiftHours = '06:00 – 14:00',
    this.activeTrip,
    this.checkInTime,
    this.dataOrigin = 'SIMULATED DATA',
  });

  bool get isCheckedIn => status == 'CHECKED_IN';
  bool get isPaired => pairingStatus == 'PAIRED';

  factory ConductorShiftModel.fromJson(Map<String, dynamic> json) {
    return ConductorShiftModel(
      dutyId: json['duty_id'] as String? ?? 'DUTY-KL-402',
      staffName: json['staff_name'] as String? ?? 'Suresh Kumar',
      staffId: json['staff_id'] as String? ?? '',
      role: json['role'] as String? ?? 'DRIVER_CONDUCTOR',
      status: json['status'] as String? ?? 'CHECKED_IN',
      pairingStatus: json['pairing_status'] as String? ?? 'PAIRED',
      busNumber: json['bus_number'] as String? ?? '205',
      routeNumber: json['route_number'] as String? ?? '12',
      shiftName: json['shift_name'] as String? ?? 'Morning Peak Corridor Shift',
      shiftHours: json['shift_hours'] as String? ?? '06:00 – 14:00',
      activeTrip: json['active_trip'] != null
          ? ConductorTripModel.fromJson(json['active_trip'] as Map<String, dynamic>)
          : null,
      checkInTime: json['check_in_time'] as String?,
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'duty_id': dutyId,
        'staff_name': staffName,
        'staff_id': staffId,
        'role': role,
        'status': status,
        'pairing_status': pairingStatus,
        'bus_number': busNumber,
        'route_number': routeNumber,
        'shift_name': shiftName,
        'shift_hours': shiftHours,
        'active_trip': activeTrip?.toJson(),
        'check_in_time': checkInTime,
        'data_origin': dataOrigin,
      };

  ConductorShiftModel copyWith({
    String? dutyId,
    String? staffName,
    String? staffId,
    String? role,
    String? status,
    String? pairingStatus,
    String? busNumber,
    String? routeNumber,
    String? shiftName,
    String? shiftHours,
    ConductorTripModel? activeTrip,
    String? checkInTime,
    String? dataOrigin,
  }) {
    return ConductorShiftModel(
      dutyId: dutyId ?? this.dutyId,
      staffName: staffName ?? this.staffName,
      staffId: staffId ?? this.staffId,
      role: role ?? this.role,
      status: status ?? this.status,
      pairingStatus: pairingStatus ?? this.pairingStatus,
      busNumber: busNumber ?? this.busNumber,
      routeNumber: routeNumber ?? this.routeNumber,
      shiftName: shiftName ?? this.shiftName,
      shiftHours: shiftHours ?? this.shiftHours,
      activeTrip: activeTrip ?? this.activeTrip,
      checkInTime: checkInTime ?? this.checkInTime,
      dataOrigin: dataOrigin ?? this.dataOrigin,
    );
  }
}

class ConductorTripCompletionModel {
  final String tripId;
  final String busNumber;
  final String routeNumber;
  final String status;
  final String completedAt;
  final int tripDurationMinutes;
  final double finalOccupancyPct;
  final int ticketsValidatedCount;
  final int layoverMinutes;
  final String? notes;
  final String dataOrigin;

  const ConductorTripCompletionModel({
    required this.tripId,
    required this.busNumber,
    required this.routeNumber,
    this.status = 'COMPLETED',
    required this.completedAt,
    this.tripDurationMinutes = 42,
    this.finalOccupancyPct = 45.0,
    this.ticketsValidatedCount = 18,
    this.layoverMinutes = 15,
    this.notes,
    this.dataOrigin = 'SIMULATED DATA',
  });

  factory ConductorTripCompletionModel.fromJson(Map<String, dynamic> json) {
    return ConductorTripCompletionModel(
      tripId: json['trip_id'] as String? ?? 'trip-sim-205',
      busNumber: json['bus_number'] as String? ?? '205',
      routeNumber: json['route_number'] as String? ?? '12',
      status: json['status'] as String? ?? 'COMPLETED',
      completedAt: json['completed_at'] as String? ?? DateTime.now().toIso8601String(),
      tripDurationMinutes: json['trip_duration_minutes'] as int? ?? 42,
      finalOccupancyPct: (json['final_occupancy_pct'] as num?)?.toDouble() ?? 45.0,
      ticketsValidatedCount: json['tickets_validated_count'] as int? ?? 18,
      layoverMinutes: json['layover_minutes'] as int? ?? 15,
      notes: json['notes'] as String?,
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }
}
