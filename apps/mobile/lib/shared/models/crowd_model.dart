import 'bus_model.dart';

/// Cabin Occupancy & Crowd Density Model
class CrowdModel {
  final String busId;
  final String busNumber;
  final double occupancyPct;
  final int passengerCount;
  final int capacity;
  final CrowdLevel crowdLevel;
  final String detectionSource;
  final String privacyStandard;
  final String timestamp;
  final String dataOrigin;

  const CrowdModel({
    required this.busId,
    required this.busNumber,
    required this.occupancyPct,
    required this.passengerCount,
    required this.capacity,
    required this.crowdLevel,
    this.detectionSource = 'Simulated_Camera_YOLOv8',
    this.privacyStandard = 'PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION',
    required this.timestamp,
    this.dataOrigin = 'SIMULATED DATA',
  });

  double get occupancyPercentage => occupancyPct;
  int get seatedPassengers => passengerCount > 35 ? 35 : passengerCount;
  int get standingPassengers => passengerCount > 35 ? passengerCount - 35 : 0;
  int get totalCapacity => capacity;

  factory CrowdModel.fromJson(Map<String, dynamic> json) {
    return CrowdModel(
      busId: json['bus_id'] as String? ?? '',
      busNumber: json['bus_number'] as String? ?? '',
      occupancyPct: (json['occupancy_pct'] as num?)?.toDouble() ??
          (json['occupancy_percentage'] as num?)?.toDouble() ??
          0.0,
      passengerCount: json['passenger_count'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 55,
      crowdLevel: CrowdLevel.fromString(json['crowd_level'] as String?),
      detectionSource: json['detection_source'] as String? ?? 'Simulated_Camera_YOLOv8',
      privacyStandard: json['privacy_standard'] as String? ?? 'PERSON_COUNTING_ONLY_NO_FACIAL_RECOGNITION',
      timestamp: json['timestamp'] as String? ?? '',
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'bus_id': busId,
        'bus_number': busNumber,
        'occupancy_pct': occupancyPct,
        'passenger_count': passengerCount,
        'capacity': capacity,
        'crowd_level': crowdLevel.value,
        'detection_source': detectionSource,
        'privacy_standard': privacyStandard,
        'timestamp': timestamp,
        'data_origin': dataOrigin,
      };
}
