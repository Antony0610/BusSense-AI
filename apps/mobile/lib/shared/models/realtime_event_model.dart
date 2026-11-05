/// BusSense AI - Realtime Event Model
/// Envelope model for WebSocket and Polling events in Flutter Mobile
class RealtimeEventModel {
  final String eventId;
  final String eventType;
  final String entityId;
  final String occurredAt;
  final String publishedAt;
  final String dataOrigin;
  final String schemaVersion;
  final Map<String, dynamic> payload;

  const RealtimeEventModel({
    required this.eventId,
    required this.eventType,
    required this.entityId,
    required this.occurredAt,
    required this.publishedAt,
    required this.dataOrigin,
    this.schemaVersion = '1.0.0',
    required this.payload,
  });

  factory RealtimeEventModel.fromJson(Map<String, dynamic> json) {
    return RealtimeEventModel(
      eventId: json['event_id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      occurredAt: json['occurred_at'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
      schemaVersion: json['schema_version'] as String? ?? '1.0.0',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'event_type': eventType,
        'entity_id': entityId,
        'occurred_at': occurredAt,
        'published_at': publishedAt,
        'data_origin': dataOrigin,
        'schema_version': schemaVersion,
        'payload': payload,
      };
}
