import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/shared/models/alert_model.dart';
import 'package:bussense_mobile/shared/models/bus_model.dart';
import 'package:bussense_mobile/shared/models/crowd_model.dart';
import 'package:bussense_mobile/shared/models/location_model.dart';
import 'package:bussense_mobile/shared/models/payment_model.dart';
import 'package:bussense_mobile/shared/models/prediction_model.dart';
import 'package:bussense_mobile/shared/models/route_model.dart';
import 'package:bussense_mobile/shared/models/ticket_model.dart';
import 'package:bussense_mobile/shared/models/trip_model.dart';
import 'package:bussense_mobile/shared/models/user_model.dart';

void main() {
  group('UserModel Serialization', () {
    test('serializes and deserializes correctly', () {
      final json = {
        'id': 'u-1',
        'email': 'commuter@bussense.ai',
        'full_name': 'Aarav Nair',
        'phone': '+919876543210',
        'role': 'PASSENGER',
        'is_active': true,
      };

      final user = UserModel.fromJson(json);
      expect(user.id, equals('u-1'));
      expect(user.fullName, equals('Aarav Nair'));
      expect(user.role, equals(UserRole.passenger));
      expect(user.isActive, isTrue);

      final serialized = user.toJson();
      expect(serialized['id'], equals('u-1'));
      expect(serialized['role'], equals('PASSENGER'));
    });
  });

  group('BusModel Serialization', () {
    test('handles standard backend payload and snake_case', () {
      final json = {
        'id': 'bus-101',
        'bus_number': 'KL-07-CE-2401',
        'route_id': 'route-1',
        'capacity': 48,
        'current_occupancy': 24,
        'status': 'ACTIVE',
        'is_active': true,
      };

      final bus = BusModel.fromJson(json);
      expect(bus.busNumber, equals('KL-07-CE-2401'));
      expect(bus.capacity, equals(48));
      expect(bus.currentOccupancy, equals(24));
      expect(bus.occupancyPercentage, equals(50.0));

      final serialized = bus.toJson();
      expect(serialized['bus_number'], equals('KL-07-CE-2401'));
    });
  });

  group('RouteModel & StopModel Serialization', () {
    test('parses route with nested stops', () {
      final json = {
        'id': 'r-1',
        'route_number': '101',
        'name': 'Aluva - Fort Kochi',
        'origin': 'Aluva Metro',
        'destination': 'Fort Kochi Bus Terminus',
        'distance_km': 28.5,
        'stops': [
          {
            'id': 's-1',
            'name': 'Aluva Metro Station',
            'latitude': 10.1076,
            'longitude': 76.3533,
            'sequence_order': 1,
            'fare_stage': 1,
          },
          {
            'id': 's-2',
            'name': 'Edapally Toll',
            'latitude': 10.0261,
            'longitude': 76.3125,
            'sequence_order': 2,
            'fare_stage': 2,
          }
        ],
      };

      final route = RouteModel.fromJson(json);
      expect(route.routeNumber, equals('101'));
      expect(route.stops.length, equals(2));
      expect(route.stops.first.name, equals('Aluva Metro Station'));
      expect(route.stops.first.fareStage, equals(1));
    });
  });

  group('TripModel Serialization', () {
    test('deserializes trip with date and optional delay', () {
      final json = {
        'id': 'trip-001',
        'bus_id': 'bus-1',
        'route_id': 'route-1',
        'start_time': '2026-09-27T08:00:00Z',
        'end_time': '2026-09-27T09:30:00Z',
        'status': 'IN_TRANSIT',
        'delay_minutes': 4,
      };

      final trip = TripModel.fromJson(json);
      expect(trip.id, equals('trip-001'));
      expect(trip.status, equals('IN_TRANSIT'));
      expect(trip.delayMinutes, equals(4));
    });
  });

  group('LocationModel Serialization', () {
    test('deserializes GPS telemetric payload', () {
      final json = {
        'bus_id': 'bus-1',
        'bus_number': 'KL-07-CE-2401',
        'latitude': 9.9816,
        'longitude': 76.2999,
        'speed_kmh': 36.5,
        'heading': 180.0,
        'timestamp': '2026-09-27T10:00:00Z',
        'current_stop': 'MG Road',
        'next_stop': 'Maharajas College',
      };

      final location = LocationModel.fromJson(json);
      expect(location.latitude, equals(9.9816));
      expect(location.speedKmh, equals(36.5));
      expect(location.nextStop, equals('Maharajas College'));
    });
  });

  group('CrowdModel & PredictionModel Serialization', () {
    test('parses crowd estimation data', () {
      final json = {
        'bus_id': 'bus-1',
        'bus_number': 'KL-07-CE-2401',
        'passenger_count': 32,
        'capacity': 40,
        'occupancy_percentage': 80.0,
        'crowd_level': 'HIGH',
        'source': 'CV_SIMULATION',
        'timestamp': '2026-09-27T10:00:00Z',
      };

      final crowd = CrowdModel.fromJson(json);
      expect(crowd.passengerCount, equals(32));
      expect(crowd.crowdLevel, equals(CrowdLevel.crowded));
      expect(crowd.occupancyPercentage, equals(80.0));
    });

    test('parses prediction estimates', () {
      final json = {
        'bus_number': 'KL-07-CE-2401',
        'route_id': 'route-1',
        'predicted_occupancy': 35,
        'predicted_crowd_level': 'MODERATE',
        'confidence_score': 0.88,
        'estimated_delay_minutes': 5,
        'horizon_minutes': 15,
        'model_version': 'xgboost-demand-v1',
      };

      final prediction = PredictionModel.fromJson(json);
      expect(prediction.predictedOccupancy, equals(35));
      expect(prediction.confidenceScore, equals(0.88));
      expect(prediction.modelVersion, equals('xgboost-demand-v1'));
    });
  });

  group('AlertModel Serialization', () {
    test('parses operational transit alert', () {
      final json = {
        'id': 'alt-1',
        'title': 'Traffic Congestion at Vyttila',
        'message': 'Heavy delay expected along Hub intersection.',
        'severity': 'WARNING',
        'category': 'TRAFFIC',
        'is_active': true,
        'timestamp': '2026-09-27T10:15:00Z',
      };

      final alert = AlertModel.fromJson(json);
      expect(alert.title, equals('Traffic Congestion at Vyttila'));
      expect(alert.severity, equals('WARNING'));
      expect(alert.isActive, isTrue);
    });
  });

  group('TicketModel & PaymentModel Serialization', () {
    test('parses digital QR ticket', () {
      final json = {
        'id': 'tkt-12345',
        'user_id': 'u-1',
        'trip_id': 'trip-001',
        'route_number': '101',
        'origin': 'Aluva',
        'destination': 'Edapally',
        'fare_amount': 25.0,
        'status': 'ACTIVE',
        'qr_data': 'BUSSENSE:TKT:12345:HASH',
        'created_at': '2026-09-27T10:00:00Z',
      };

      final ticket = TicketModel.fromJson(json);
      expect(ticket.id, equals('tkt-12345'));
      expect(ticket.fareAmount, equals(25.0));
      expect(ticket.status, equals('ACTIVE'));
      expect(ticket.qrData, equals('BUSSENSE:TKT:12345:HASH'));
    });

    test('parses payment confirmation model', () {
      final json = {
        'id': 'pay-999',
        'ticket_id': 'tkt-12345',
        'user_id': 'u-1',
        'amount': 25.0,
        'currency': 'INR',
        'payment_method': 'UPI',
        'status': 'SUCCESS',
        'transaction_reference': 'TXN_KSRTC_999',
        'created_at': '2026-09-27T10:00:05Z',
      };

      final payment = PaymentModel.fromJson(json);
      expect(payment.amount, equals(25.0));
      expect(payment.currency, equals('INR'));
      expect(payment.status, equals('SUCCESS'));
    });
  });
}
