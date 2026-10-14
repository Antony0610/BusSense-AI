import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/app/app.dart';
import 'package:bussense_mobile/core/config/env_config.dart';
import 'package:bussense_mobile/core/network/api_client.dart';
import 'package:bussense_mobile/core/storage/secure_token_storage.dart';
import 'package:bussense_mobile/features/auth/controllers/auth_controller.dart';
import 'package:bussense_mobile/features/conductor/views/conductor_shell.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_shell.dart';
import 'package:bussense_mobile/shared/models/user_model.dart';
import 'package:bussense_mobile/shared/widgets/bussense_button.dart';

void main() {
  testWidgets('BusSenseApp initializes and shows initial state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const BusSenseApp(),
      ),
    );

    // Initial session restoration state shows loading or unauthenticated
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpAndSettle();
    // After async initialization without saved token, shows AuthEntryScreen
    expect(find.text('BusSense AI'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Passenger role routes to PassengerShell with 5 navigation destinations', (WidgetTester tester) async {
    const passengerUser = UserModel(
      id: 'p-1',
      email: 'passenger@bussense.ai',
      fullName: 'Aarav Nair',
      role: UserRole.passenger,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authControllerProvider.overrideWith(
            (ref) => _StaticMockAuthController(const Authenticated(passengerUser)),
          ),
        ],
        child: const BusSenseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify PassengerShell is active
    expect(find.byType(PassengerShell), findsOneWidget);
    expect(find.text('PASSENGER'), findsOneWidget);

    // Verify initial destination is Live Departures
    expect(find.text('Live Departures'), findsWidgets);

    // Verify Bottom Navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap on Explore tab
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Corridors'), findsWidgets);

    // Tap on Tickets tab
    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();
    expect(find.text('Digital Tickets'), findsWidgets);

    // Tap on AI tab (functional BusSense AI Assistant)
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    expect(find.text('BusSense AI'), findsWidgets);

    // Tap on Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Commuter Profile'), findsWidgets);
    expect(find.text('Aarav Nair'), findsOneWidget);
  });

  testWidgets('Conductor role routes to ConductorShell with 5 operational destinations', (WidgetTester tester) async {
    const conductorUser = UserModel(
      id: 'c-1',
      email: 'conductor@bussense.ai',
      fullName: 'Rajesh Kumar',
      role: UserRole.driverConductor,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authControllerProvider.overrideWith(
            (ref) => _StaticMockAuthController(const Authenticated(conductorUser)),
          ),
        ],
        child: const BusSenseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify ConductorShell is active
    expect(find.byType(ConductorShell), findsOneWidget);
    expect(find.text('CONDUCTOR'), findsOneWidget);

    // Verify initial destination is Active Trip HUD
    expect(find.text('Active Trip HUD'), findsWidgets);

    // Verify Bottom Navigation items exist
    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap on Scan tab
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('QR Pass Scanner'), findsWidgets);

    // Tap on Bus tab
    await tester.tap(find.text('Bus'));
    await tester.pumpAndSettle();
    expect(find.text('Vehicle Telemetry'), findsWidgets);

    // Tap on Alerts tab
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Crew Alerts'), findsWidgets);

    // Tap on Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Crew Profile'), findsWidgets);
    expect(find.text('Rajesh Kumar'), findsOneWidget);
  });

  testWidgets('Authority role displays Web Portal redirect warning on mobile', (WidgetTester tester) async {
    const authorityUser = UserModel(
      id: 'a-1',
      email: 'authority@bussense.ai',
      fullName: 'KSRTC Operations',
      role: UserRole.authority,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authControllerProvider.overrideWith(
            (ref) => _StaticMockAuthController(const Authenticated(authorityUser)),
          ),
        ],
        child: const BusSenseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify redirect screen is displayed
    expect(find.text('Authority Web Portal Required'), findsOneWidget);
    expect(find.textContaining('restricted to the web console'), findsOneWidget);
    expect(find.textContaining(EnvConfig.authorityPortalUrl), findsOneWidget);
  });

  testWidgets('Authority role displays custom configured Authority Portal URL', (WidgetTester tester) async {
    const authorityUser = UserModel(
      id: 'a-2',
      email: 'ops@bussense.kerala.gov.in',
      fullName: 'Chief Controller',
      role: UserRole.authority,
    );

    final initialUrl = EnvConfig.authorityPortalUrl;
    EnvConfig.setAuthorityPortalUrl('https://custom-ops.kerala.gov.in/live-dispatch');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authControllerProvider.overrideWith(
            (ref) => _StaticMockAuthController(const Authenticated(authorityUser)),
          ),
        ],
        child: const BusSenseApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify custom configured URL is displayed
    expect(find.text('Authority Web Portal Required'), findsOneWidget);
    expect(find.textContaining('https://custom-ops.kerala.gov.in/live-dispatch'), findsOneWidget);

    EnvConfig.setAuthorityPortalUrl(initialUrl); // Restore
  });

  testWidgets('Logout action returns user to unauthenticated state', (WidgetTester tester) async {
    const passengerUser = UserModel(
      id: 'p-1',
      email: 'passenger@bussense.ai',
      fullName: 'Aarav Nair',
      role: UserRole.passenger,
    );

    final mockController = _InteractiveMockAuthController(const Authenticated(passengerUser));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const BusSenseApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(PassengerShell), findsOneWidget);

    // Navigate to profile tab to find logout button
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Tap sign out
    final signOutButton = find.widgetWithText(BusSenseButton, 'Sign Out');
    expect(signOutButton, findsOneWidget);
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    // Verify user is returned to AuthEntryScreen
    expect(find.text('BusSense AI'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}

/// Helper mock controller with fixed initial state
class _StaticMockAuthController extends AuthController {
  final AuthState fixedState;
  _StaticMockAuthController(this.fixedState)
      : super(
          ApiClient(tokenStorage: InMemoryTokenStorage()),
          InMemoryTokenStorage(),
        ) {
    state = fixedState;
  }

  @override
  Future<void> restoreSession() async {
    state = fixedState;
  }
}

/// Helper mock controller allowing state change on logout
class _InteractiveMockAuthController extends AuthController {
  final AuthState initialState;
  _InteractiveMockAuthController(this.initialState)
      : super(
          ApiClient(tokenStorage: InMemoryTokenStorage()),
          InMemoryTokenStorage(),
        ) {
    state = initialState;
  }

  @override
  Future<void> restoreSession() async {
    state = initialState;
  }

  @override
  Future<void> logout() async {
    state = const Unauthenticated();
  }
}
