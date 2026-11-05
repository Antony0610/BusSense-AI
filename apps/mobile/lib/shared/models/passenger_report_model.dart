/// Passenger Issue / Incident Report
class PassengerReportModel {
  final String id;
  final String category;
  final String title;
  final String description;
  final String? busNumber;
  final String? routeNumber;
  final String status;
  final String createdAt;

  const PassengerReportModel({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.busNumber,
    this.routeNumber,
    this.status = 'REPORTED',
    required this.createdAt,
  });

  String get categoryDisplay {
    switch (category) {
      case 'BUS_VEHICLE':
        return 'Bus / Vehicle';
      case 'ROUTE_DELAY':
        return 'Route / Delay';
      case 'TICKET_PAYMENT':
        return 'Ticket / Payment';
      case 'LOCATION_ETA':
        return 'Incorrect Location / ETA';
      case 'CROWD_FORECAST':
        return 'Crowd Forecast';
      case 'APP_BUG':
        return 'App Bug';
      case 'OTHER':
      default:
        return 'Other';
    }
  }

  factory PassengerReportModel.fromJson(Map<String, dynamic> json) {
    return PassengerReportModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      busNumber: json['bus_number'] as String?,
      routeNumber: json['route_number'] as String?,
      status: json['status'] as String? ?? 'REPORTED',
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'description': description,
        'bus_number': busNumber,
        'route_number': routeNumber,
        'status': status,
        'created_at': createdAt,
      };

  PassengerReportModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    String? busNumber,
    String? routeNumber,
    String? status,
    String? createdAt,
  }) {
    return PassengerReportModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      busNumber: busNumber ?? this.busNumber,
      routeNumber: routeNumber ?? this.routeNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
