import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/core/config/env_config.dart';
import 'package:bussense_mobile/core/errors/app_exception.dart';
import 'package:bussense_mobile/core/network/api_client.dart';
import 'package:bussense_mobile/core/storage/secure_token_storage.dart';
import 'package:bussense_mobile/core/utils/jwt_decoder.dart';
import 'package:bussense_mobile/shared/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('EnvConfig Tests', () {
    test('dynamic base URL override trims trailing slashes', () {
      final initial = EnvConfig.apiBaseUrl;
      EnvConfig.setBaseUrl('http://192.168.1.100:8000/api/');
      expect(EnvConfig.apiBaseUrl, equals('http://192.168.1.100:8000/api'));
      EnvConfig.setBaseUrl(initial); // Restore
    });

    test('default platform urls are defined', () {
      expect(EnvConfig.defaultAndroidUrl, contains('10.0.2.2'));
      expect(EnvConfig.defaultIosUrl, contains('localhost'));
    });

    test('authority portal URL is configurable and has correct default', () {
      final initial = EnvConfig.authorityPortalUrl;
      expect(initial, contains('3000/authority/command'));

      EnvConfig.setAuthorityPortalUrl('https://ops.bussense.kerala.gov.in/command');
      expect(EnvConfig.authorityPortalUrl, equals('https://ops.bussense.kerala.gov.in/command'));

      EnvConfig.setAuthorityPortalUrl(initial); // Restore
    });
  });

  group('UserRole Enum & Parsing Tests', () {
    test('parses PASSENGER correctly', () {
      expect(UserRole.fromString('PASSENGER'), equals(UserRole.passenger));
      expect(UserRole.fromString('passenger'), equals(UserRole.passenger));
    });

    test('parses DRIVER_CONDUCTOR correctly', () {
      expect(UserRole.fromString('DRIVER_CONDUCTOR'), equals(UserRole.driverConductor));
      expect(UserRole.fromString('driver_conductor'), equals(UserRole.driverConductor));
      expect(UserRole.fromString('CONDUCTOR'), equals(UserRole.driverConductor));
    });

    test('parses AUTHORITY correctly', () {
      expect(UserRole.fromString('AUTHORITY'), equals(UserRole.authority));
      expect(UserRole.fromString('authority'), equals(UserRole.authority));
    });

    test('unknown role defaults safely to passenger', () {
      expect(UserRole.fromString('UNKNOWN_ROLE'), equals(UserRole.passenger));
      expect(UserRole.fromString(null), equals(UserRole.passenger));
    });

    test('toBackendString returns exact backend role constants', () {
      expect(UserRole.passenger.toBackendString(), equals('PASSENGER'));
      expect(UserRole.driverConductor.toBackendString(), equals('DRIVER_CONDUCTOR'));
      expect(UserRole.authority.toBackendString(), equals('AUTHORITY'));
    });
  });

  group('JwtDecoder Tests', () {
    // Valid token: sub=user-123, email=passenger@bussense.ai, full_name=Test Commuter, role=PASSENGER, exp=2000000000
    const validJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEyMyIsImVtYWlsIjoicGFzc2VuZ2VyQGJ1c3NlbnNlLmFpIiwiZnVsbF9uYW1lIjoiVGVzdCBDb21tdXRlciIsInJvbGUiOiJQQVNTRU5HRVIiLCJleHAiOjIwMDAwMDAwMDB9.signature';

    // Expired token: sub=user-456, role=DRIVER_CONDUCTOR, exp=1000000000
    const expiredJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTQ1NiIsInJvbGUiOiJEUklWRVJfQ09ORFVDVE9SIiwiZXhwIjoxMDAwMDAwMDAwfQ.signature';

    test('decodes payload claims accurately', () {
      final payload = JwtDecoder.decode(validJwt);
      expect(payload, isNotNull);
      expect(payload!['sub'], equals('user-123'));
      expect(payload['email'], equals('passenger@bussense.ai'));
      expect(payload['role'], equals('PASSENGER'));
    });

    test('detects expired tokens correctly', () {
      expect(JwtDecoder.isExpired(validJwt), isFalse);
      expect(JwtDecoder.isExpired(expiredJwt), isTrue);
    });

    test('extracts UserRole correctly from JWT', () {
      expect(JwtDecoder.getRole(validJwt), equals(UserRole.passenger));
      expect(JwtDecoder.getRole(expiredJwt), equals(UserRole.driverConductor));
    });

    test('extracts UserModel cleanly from JWT', () {
      final user = JwtDecoder.toUserModel(validJwt);
      expect(user, isNotNull);
      expect(user!.id, equals('user-123'));
      expect(user.email, equals('passenger@bussense.ai'));
      expect(user.fullName, equals('Test Commuter'));
      expect(user.role, equals(UserRole.passenger));
    });

    test('malformed JWT safely returns null or empty', () {
      expect(JwtDecoder.decode('invalid-token'), isNull);
    });
  });

  group('InMemoryTokenStorage Tests', () {
    test('stores, retrieves, and clears authentication tokens', () async {
      final storage = InMemoryTokenStorage();

      expect(await storage.getToken(), isNull);
      expect(await storage.hasToken(), isFalse);

      await storage.saveToken('secure-jwt-token-xyz');
      expect(await storage.getToken(), equals('secure-jwt-token-xyz'));
      expect(await storage.hasToken(), isTrue);

      await storage.clearToken();
      expect(await storage.getToken(), isNull);
      expect(await storage.hasToken(), isFalse);
    });
  });

  group('ApiClient Tests', () {
    test('attaches Authorization header when token is supplied', () async {
      final storage = InMemoryTokenStorage();
      await storage.saveToken('bearer-token-123');

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer bearer-token-123'));
        expect(request.headers['Content-Type'], equals('application/json'));
        return http.Response('{"status": "ok"}', 200);
      });

      final apiClient = ApiClient(tokenStorage: storage, client: mockClient);
      final response = await apiClient.get('/test');
      expect(response['status'], equals('ok'));
    });

    test('maps 401 response to AuthException', () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Could not validate credentials"}', 401);
      });

      final apiClient = ApiClient(tokenStorage: storage, client: mockClient);
      expect(
        () async => await apiClient.get('/protected'),
        throwsA(isA<AuthException>()),
      );
    });

    test('maps 403 response to RoleException', () async {
      final storage = InMemoryTokenStorage();
      final mockClient = MockClient((request) async {
        return http.Response('{"detail": "Insufficient permissions"}', 403);
      });

      final apiClient = ApiClient(tokenStorage: storage, client: mockClient);
      expect(
        () async => await apiClient.get('/admin-only'),
        throwsA(isA<RoleException>()),
      );
    });

    test('maps 404 and 500 responses to NetworkException', () async {
      final storage = InMemoryTokenStorage();
      final notFoundClient = MockClient((request) async {
        return http.Response('{"detail": "Bus not found"}', 404);
      });

      final notFoundApiClient = ApiClient(tokenStorage: storage, client: notFoundClient);
      expect(
        () async => await notFoundApiClient.get('/buses/999'),
        throwsA(isA<NetworkException>()),
      );

      final serverErrorClient = MockClient((request) async {
        return http.Response('{"detail": "Internal database error"}', 500);
      });

      final serverErrorApiClient = ApiClient(tokenStorage: storage, client: serverErrorClient);
      expect(
        () async => await serverErrorApiClient.get('/faulty'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
