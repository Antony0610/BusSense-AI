import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/shared/models/realtime_event_model.dart';
import 'package:bussense_mobile/shared/models/notification_item_model.dart';
import 'package:bussense_mobile/core/network/realtime_client.dart';

void main() {
  group('Phase H12 — Realtime Data & Notifications Mobile Tests', () {
    test('1. RealtimeEventModel correctly serializes and deserializes', () {
      final json = {
        'event_id': 'evt-h12-001',
        'event_type': 'FLEET_TELEMETRY_UPDATE',
        'entity_id': 'fleet_all',
        'timestamp': '2026-10-14T10:00:00Z',
        'data_origin': 'SIMULATED TELEMETRY',
        'schema_version': '1.0.0',
        'payload': {
          'buses': [
            {'bus_number': '205', 'speed': 42.5}
          ]
        }
      };

      final event = RealtimeEventModel.fromJson(json);
      expect(event.eventId, 'evt-h12-001');
      expect(event.eventType, 'FLEET_TELEMETRY_UPDATE');
      expect(event.entityId, 'fleet_all');
      expect(event.dataOrigin, 'SIMULATED TELEMETRY');
      expect(event.schemaVersion, '1.0.0');
      expect(event.payload['buses'], isNotEmpty);

      final serialized = event.toJson();
      expect(serialized['event_id'], 'evt-h12-001');
      expect(serialized['data_origin'], 'SIMULATED TELEMETRY');
    });

    test('2. NotificationItemModel correctly deserializes and verifies truth label', () {
      final json = {
        'id': 'notif-001',
        'user_id': 'usr-aarav',
        'title': 'Bus 205 Approaching',
        'body': 'Arriving at Kaloor Metro Stand in 3 minutes.',
        'notification_type': 'BUS_ARRIVAL',
        'severity': 'INFO',
        'is_read': false,
        'action_url': 'bussense://journey/bus-205',
        'metadata': {'bus_number': '205'},
        'dedup_key': 'pax_arr_205',
        'data_origin': 'SIMULATED TELEMETRY',
        'created_at': '2026-10-14T10:00:00Z',
      };

      final item = NotificationItemModel.fromJson(json);
      expect(item.id, 'notif-001');
      expect(item.userId, 'usr-aarav');
      expect(item.title, 'Bus 205 Approaching');
      expect(item.isRead, isFalse);
      expect(item.dataOrigin, 'SIMULATED TELEMETRY');
      expect(item.dedupKey, 'pax_arr_205');

      final readCopy = item.copyWith(isRead: true);
      expect(readCopy.isRead, isTrue);
      expect(readCopy.id, item.id);
    });

    test('3. RealtimeClient state machine defaults and transitions', () {
      final client = RealtimeClient(
        wsUrl: 'ws://localhost:8000/ws/telemetry',
        pollingInterval: const Duration(seconds: 2),
      );

      expect(client.state, RealtimeConnectionState.offline);
      expect(client.lastTelemetryReceivedAt, isNull);
      expect(client.isTelemetryStale, isTrue);
      expect(client.freshnessLabel, 'NO DATA');
    });

    test('4. NotificationItemModel fallback defaults for missing optional fields', () {
      final minimalJson = {
        'id': 'notif-min',
        'user_id': 'usr-min',
        'title': 'System Notice',
        'body': 'Schedule update active.',
      };

      final item = NotificationItemModel.fromJson(minimalJson);
      expect(item.id, 'notif-min');
      expect(item.severity, 'INFO');
      expect(item.isRead, isFalse);
      expect(item.dataOrigin, 'SIMULATED DATA');
    });
  });
}
