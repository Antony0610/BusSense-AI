/// Public Service Alert / Crew Incident Advisory
class AlertModel {
  final String id;
  final String title;
  final String message;
  final String severity;
  final String affectedRoute;
  final bool isActive;
  final String createdAt;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.affectedRoute,
    required this.isActive,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      affectedRoute: json['affected_route'] as String? ?? 'Route 205',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'severity': severity,
        'affected_route': affectedRoute,
        'is_active': isActive,
        'created_at': createdAt,
      };
}
