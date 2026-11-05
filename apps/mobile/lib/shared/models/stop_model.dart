/// Transit Stop Model
class StopModel {
  final String id;
  final String stopCode;
  final String stopName;
  final String locality;
  final double latitude;
  final double longitude;
  final String? landmark;

  const StopModel({
    required this.id,
    required this.stopCode,
    required this.stopName,
    required this.locality,
    required this.latitude,
    required this.longitude,
    this.landmark,
  });

  String get name => stopName;
  int get fareStage => 1;

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] as String? ?? '',
      stopCode: json['stop_code'] as String? ?? '',
      stopName: json['stop_name'] as String? ?? json['name'] as String? ?? '',
      locality: json['locality'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      landmark: json['landmark'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stop_code': stopCode,
        'stop_name': stopName,
        'locality': locality,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
      };
}
