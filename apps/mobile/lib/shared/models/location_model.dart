/// Vehicle GPS Telemetry Model
class LocationModel {
  final String busId;
  final String busNumber;
  final String registrationNumber;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double headingDeg;
  final String currentStop;
  final String nextStop;
  final int etaNextStopMins;
  final String timestamp;
  final String dataOrigin;

  const LocationModel({
    required this.busId,
    required this.busNumber,
    required this.registrationNumber,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.headingDeg,
    required this.currentStop,
    required this.nextStop,
    required this.etaNextStopMins,
    required this.timestamp,
    this.dataOrigin = 'SIMULATED DATA',
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      busId: json['bus_id'] as String? ?? '',
      busNumber: json['bus_number'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ?? 'KL-15-A-2051',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      headingDeg: (json['heading_deg'] as num?)?.toDouble() ?? 0.0,
      currentStop: json['current_stop'] as String? ?? '',
      nextStop: json['next_stop'] as String? ?? '',
      etaNextStopMins: json['eta_next_stop_mins'] as int? ?? 0,
      timestamp: json['timestamp'] as String? ?? '',
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'bus_id': busId,
        'bus_number': busNumber,
        'registration_number': registrationNumber,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'heading_deg': headingDeg,
        'current_stop': currentStop,
        'next_stop': nextStop,
        'eta_next_stop_mins': etaNextStopMins,
        'timestamp': timestamp,
        'data_origin': dataOrigin,
      };
}
