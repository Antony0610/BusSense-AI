/// BusSense AI - In-App Notification Model
/// Represents commuter or crew transit advisories, crowding alerts, and trip updates
class NotificationItemModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final String createdAt;
  final String severity;
  final String dataOrigin;
  final String? dedupKey;

  const NotificationItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.severity = 'INFO',
    this.dataOrigin = 'SIMULATED DATA',
    this.dedupKey,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? 'TRANSIT_ALERT',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      severity: json['severity'] as String? ?? 'INFO',
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
      dedupKey: json['dedup_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'notification_type': notificationType,
        'is_read': isRead,
        'created_at': createdAt,
        'severity': severity,
        'data_origin': dataOrigin,
        'dedup_key': dedupKey,
      };

  NotificationItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? notificationType,
    bool? isRead,
    String? createdAt,
    String? severity,
    String? dataOrigin,
    String? dedupKey,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      severity: severity ?? this.severity,
      dataOrigin: dataOrigin ?? this.dataOrigin,
      dedupKey: dedupKey ?? this.dedupKey,
    );
  }
}
