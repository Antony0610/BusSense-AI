import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/app/app.dart';
import 'package:bussense_mobile/core/network/api_client.dart';
import 'package:bussense_mobile/core/storage/secure_token_storage.dart';
import 'package:bussense_mobile/features/auth/controllers/auth_controller.dart';
import 'package:bussense_mobile/features/conductor/data/conductor_repository.dart';
import 'package:bussense_mobile/features/conductor/providers/conductor_providers.dart';
import 'package:bussense_mobile/features/conductor/views/active_trip_cockpit_view.dart';
import 'package:bussense_mobile/features/conductor/views/bus_pairing_screen.dart';
import 'package:bussense_mobile/features/conductor/views/conductor_incident_screen.dart';
import 'package:bussense_mobile/features/conductor/views/conductor_occupancy_screen.dart';
import 'package:bussense_mobile/features/conductor/views/conductor_shell.dart';
import 'package:bussense_mobile/features/conductor/views/qr_ticket_validator_view.dart';
import 'package:bussense_mobile/features/conductor/views/shift_check_in_screen.dart';
import 'package:bussense_mobile/features/conductor/views/trip_completion_screen.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_shell.dart';
import 'package:bussense_mobile/shared/models/alert_model.dart';
import 'package:bussense_mobile/shared/models/bus_model.dart';
import 'package:bussense_mobile/shared/models/conductor_shift_model.dart';
import 'package:bussense_mobile/shared/models/crowd_model.dart';
import 'package:bussense_mobile/shared/models/passenger_report_model.dart';
import 'package:bussense_mobile/shared/models/ticket_validation_result_model.dart';
import 'package:bussense_mobile/shared/models/user_model.dart';

class MockConductorRepository implements IConductorRepository {
  ConductorShiftModel shift;

  MockConductorRepository({ConductorShiftModel? initialShift})
      : shift = initialShift ??
            const ConductorShiftModel(
              dutyId: 'DUTY-KL-402',
              staffName: 'Suresh Kumar',
              staffId: '22222222-2222-2222-2222-222222222222',
              status: 'CHECKED_IN',
              pairingStatus: 'PAIRED',
              busNumber: '205',
              routeNumber: '12',
              shiftName: 'Morning Peak Corridor Shift',
              shiftHours: '06:00 – 14:00',
              activeTrip: ConductorTripModel(
                tripId: 'trip-205',
                tripCode: 'TRIP-205-ACTIVE',
                busNumber: '205',
                routeNumber: '12',
                origin: 'Aluva Metro Station',
                destination: 'Vyttila Mobility Hub',
                currentStop: 'Palarivattom Jn',
                nextStop: 'Kaloor Central Stand',
                status: 'ACTIVE',
                occupancyPct: 41.8,
                crowdLevel: 'LOW',
                etaMinutes: 6,
                progressPct: 0.65,
                speedKmh: 28.5,
              ),
            );

  @override
  Future<ConductorShiftModel> getConductorShift() async => shift;

  @override
  Future<ConductorShiftModel> checkInForShift({String? dutyId}) async {
    shift = shift.copyWith(
      status: 'CHECKED_IN',
      dutyId: dutyId ?? shift.dutyId,
      checkInTime: DateTime.now().toIso8601String(),
    );
    return shift;
  }

  @override
  Future<ConductorShiftModel> pairBus({
    required String busNumber,
    required String routeNumber,
    String? tripCode,
  }) async {
    shift = shift.copyWith(
      busNumber: busNumber,
      routeNumber: routeNumber,
      pairingStatus: 'PAIRED',
    );
    return shift;
  }

  @override
  Future<ConductorShiftModel> startTrip({String? tripId, String? busNumber}) async {
    shift = shift.copyWith(
      activeTrip: shift.activeTrip?.copyWith(status: 'ACTIVE'),
    );
    return shift;
  }

  @override
  Future<ConductorTripCompletionModel> completeTrip({String? tripId, String? notes}) async {
    shift = shift.copyWith(
      activeTrip: shift.activeTrip?.copyWith(status: 'COMPLETED'),
    );
    return ConductorTripCompletionModel(
      tripId: tripId ?? 'trip-205',
      busNumber: shift.busNumber,
      routeNumber: shift.routeNumber,
      completedAt: DateTime.now().toIso8601String(),
      notes: notes,
      status: 'COMPLETED',
    );
  }

  @override
  Future<TicketValidationResultModel> validateTicket({
    required String qrHash,
    required String busNumber,
  }) async {
    if (qrHash.contains('used')) return TicketValidationResultModel.mockAlreadyUsed();
    if (qrHash.contains('expired')) return TicketValidationResultModel.mockExpired();
    if (qrHash.contains('invalid')) return TicketValidationResultModel.mockInvalid();
    return TicketValidationResultModel.mockValid();
  }

  @override
  Future<PassengerReportModel> reportIncident(PassengerReportModel report) async {
    return report.copyWith(
      id: 'INC-KL-TEST-901',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<List<AlertModel>> getCrewAlerts() async => [
        const AlertModel(
          id: 'alt-1',
          title: 'Edappally Bottleneck',
          message: 'Heavy vehicle delay of 8 minutes observed near Lulu Mall intersection.',
          severity: 'WARNING',
          affectedRoute: 'Route 12',
          isActive: true,
          createdAt: '2026-09-27T10:00:00Z',
        ),
      ];

  @override
  Future<CrowdModel?> getBusOccupancy(String busNumber) async => CrowdModel(
        busId: 'bus-$busNumber',
        busNumber: busNumber,
        occupancyPct: 41.8,
        passengerCount: 23,
        capacity: 55,
        crowdLevel: CrowdLevel.low,
        timestamp: '2026-09-27T10:00:00Z',
        dataOrigin: 'SIMULATED DATA',
      );
}

class MockAuthController extends AuthController {
  final AuthState fixedState;

  MockAuthController(this.fixedState)
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

  @override
  Future<void> logout() async {
    state = const Unauthenticated();
  }
}

void main() {
  const conductorUser = UserModel(
    id: 'c-1',
    email: 'conductor@bussense.ai',
    fullName: 'Suresh Kumar',
    role: UserRole.driverConductor,
  );

  const passengerUser = UserModel(
    id: 'p-1',
    email: 'passenger@bussense.ai',
    fullName: 'Aarav Nair',
    role: UserRole.passenger,
  );

  Widget createTestWidget(Widget child, {MockConductorRepository? mockRepo}) {
    final repo = mockRepo ?? MockConductorRepository();
    return ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        conductorRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: child is Scaffold ? child : Scaffold(body: child),
      ),
    );
  }

  void setupScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Phase H6 — Driver / Conductor Operational Experience Tests', () {
    // 1. Conductor shell renders with 5 bottom navigation tabs
    testWidgets('1. Conductor shell renders with 5 bottom navigation tabs', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const ConductorShell(user: conductorUser)));
      await tester.pumpAndSettle();

      expect(find.byType(ConductorShell), findsOneWidget);
      expect(find.text('Active Trip HUD'), findsWidgets);
      expect(find.text('CONDUCTOR'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    // 2. Conductor role routes correctly in BusSenseApp
    testWidgets('2. Conductor role routes correctly in BusSenseApp', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
            conductorRepositoryProvider.overrideWithValue(MockConductorRepository()),
            authControllerProvider.overrideWith(
              (ref) => MockAuthController(const Authenticated(conductorUser)),
            ),
          ],
          child: const BusSenseApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConductorShell), findsOneWidget);
      expect(find.text('CONDUCTOR'), findsOneWidget);
    });

    // 3. Shift check-in screen renders duty roster and performs check-in
    testWidgets('3. Shift check-in screen renders duty roster and performs check-in', (WidgetTester tester) async {
      setupScreen(tester);

      final notCheckedInShift = ConductorShiftModel(
        dutyId: 'DUTY-KL-402',
        staffName: 'Suresh Kumar',
        staffId: '22222222-2222-2222-2222-222222222222',
        status: 'NOT_CHECKED_IN',
        pairingStatus: 'UNPAIRED',
        shiftName: 'Morning Peak Corridor Shift',
        shiftHours: '06:00 – 14:00',
      );
      final repo = MockConductorRepository(initialShift: notCheckedInShift);

      await tester.pumpWidget(createTestWidget(const ShiftCheckInScreen(user: conductorUser), mockRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Crew Shift Check-In'), findsOneWidget);
      expect(find.text('DUTY-KL-402'), findsOneWidget);
      expect(find.text('Morning Peak Corridor Shift'), findsOneWidget);
      expect(find.text('Start Shift Duty'), findsOneWidget);

      await tester.tap(find.text('Start Shift Duty'));
      await tester.pumpAndSettle();

      expect(find.text('Shift duty started. Proceeding to active cockpit.'), findsOneWidget);
    });

    // 4. Bus pairing confirms bus, route, and corridor
    testWidgets('4. Bus pairing confirms bus, route, and corridor', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const BusPairingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bus & Route Pairing'), findsOneWidget);
      expect(find.text('BUS 205'), findsOneWidget);
      expect(find.text('BUS 14A'), findsOneWidget);

      // Select Bus 14A
      await tester.tap(find.text('BUS 14A'));
      await tester.pumpAndSettle();

      // Tap Confirm Pairing
      await tester.tap(find.text('Confirm Pairing'));
      await tester.pumpAndSettle();

      expect(find.text('Vehicle pairing confirmed: Bus 14A on Route 3B'), findsOneWidget);
    });

    // 5. Active trip cockpit displays glanceable stops, ETA, and occupancy
    testWidgets('5. Active trip cockpit displays glanceable stops, ETA, and occupancy', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const ActiveTripCockpitView(user: conductorUser)));
      await tester.pumpAndSettle();

      expect(find.text('BUS 205'), findsOneWidget);
      expect(find.text('ROUTE 12'), findsOneWidget);
      expect(find.text('Palarivattom Jn'), findsOneWidget);
      expect(find.text('Kaloor Central Stand'), findsOneWidget);
      expect(find.text('6 MIN'), findsOneWidget);
      expect(find.textContaining('42%'), findsOneWidget);
      expect(find.text('View Occupancy & Seating Gauge'), findsOneWidget);
      expect(find.text('Scan Passenger QR Pass'), findsOneWidget);
      expect(find.text('Report Route / Vehicle Incident'), findsOneWidget);
      expect(find.text('Complete Trip & Start Layover'), findsOneWidget);
      expect(find.textContaining('SAFETY NOTICE:'), findsOneWidget);
    });

    // 6. Occupancy screen renders seated, standing, and threshold bars
    testWidgets('6. Occupancy screen renders seated, standing, and threshold bars', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const ConductorOccupancyScreen(busNumber: '205')));
      await tester.pumpAndSettle();

      expect(find.text('Cabin Occupancy'), findsOneWidget);
      expect(find.text('BUS 205 CABIN DENSITY'), findsOneWidget);
      expect(find.text('41.8%'), findsOneWidget);
      expect(find.text('23 / 35'), findsOneWidget);
      expect(find.text('LOW (< 50%)'), findsOneWidget);
      expect(find.text('MODERATE (50–80%)'), findsOneWidget);
      expect(find.text('CROWDED (> 80%)'), findsOneWidget);
      expect(find.text('SIMULATED DATA • ZERO BIOMETRICS'), findsOneWidget);
    });

    // 7. QR scanner viewfinder and test action buttons render
    testWidgets('7. QR scanner viewfinder and test action buttons render', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const QrTicketValidatorView(busNumber: '205')));
      await tester.pumpAndSettle();

      expect(find.text('CAMERA SCAN DEFERRED • PROTOTYPE VIEW'), findsOneWidget);
      expect(find.text('Rapid Test Scenarios'), findsOneWidget);
      expect(find.text('Valid Pass'), findsOneWidget);
      expect(find.text('Already Used'), findsOneWidget);
      expect(find.text('Expired Pass'), findsOneWidget);
      expect(find.text('Invalid QR'), findsOneWidget);
    });

    // 8. Valid ticket verification displays VALID status
    testWidgets('8. Valid ticket verification displays VALID status', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const QrTicketValidatorView(busNumber: '205')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Valid Pass'));
      await tester.pumpAndSettle();

      expect(find.text('VALID'), findsWidgets);
      expect(find.text('#TKT-1042'), findsOneWidget);
      expect(find.text('Vyttila Mobility Hub'), findsOneWidget);
      expect(find.text('Dismiss Result'), findsOneWidget);
    });

    // 9. Invalid ticket verification displays INVALID status
    testWidgets('9. Invalid ticket verification displays INVALID status', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const QrTicketValidatorView(busNumber: '205')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Invalid QR'));
      await tester.pumpAndSettle();

      expect(find.text('INVALID'), findsWidgets);
      expect(find.text('Unrecognized or invalid QR ticket. No matching boarding record found.'), findsOneWidget);
    });

    // 10. Expired ticket verification displays EXPIRED status
    testWidgets('10. Expired ticket verification displays EXPIRED status', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const QrTicketValidatorView(busNumber: '205')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expired Pass'));
      await tester.pumpAndSettle();

      expect(find.text('EXPIRED'), findsWidgets);
      expect(find.text('This ticket has expired past its boarding validity window.'), findsOneWidget);
    });

    // 11. Already-used ticket verification displays ALREADY USED status
    testWidgets('11. Already-used ticket verification displays ALREADY USED status', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const QrTicketValidatorView(busNumber: '205')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Already Used'));
      await tester.pumpAndSettle();

      expect(find.text('ALREADY USED'), findsWidgets);
      expect(find.text('This digital ticket has already been used and validated by a conductor.'), findsOneWidget);
    });

    // 12. Incident reporting validates form and submits report with reference
    testWidgets('12. Incident reporting validates form and submits report with reference', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(createTestWidget(const ConductorIncidentScreen(busNumber: '205', routeNumber: '12')));
      await tester.pumpAndSettle();

      expect(find.text('Incident Category'), findsOneWidget);
      expect(find.text('Route Obstruction'), findsOneWidget);
      expect(find.text('Report Incident'), findsOneWidget);

      // Submit report
      await tester.tap(find.text('Report Incident'));
      await tester.pumpAndSettle();

      expect(find.text('Incident Logged to Dispatch'), findsOneWidget);
      expect(find.text('INC-KL-TEST-901'), findsOneWidget);
    });

    // 13. Trip completion summarizes trip and completes active status
    testWidgets('13. Trip completion summarizes trip and completes active status', (WidgetTester tester) async {
      setupScreen(tester);

      const trip = ConductorTripModel(
        tripId: 'trip-205',
        tripCode: 'TRIP-205-ACTIVE',
        busNumber: '205',
        routeNumber: '12',
        origin: 'Aluva Metro Station',
        destination: 'Vyttila Mobility Hub',
        currentStop: 'Vyttila Mobility Hub',
        nextStop: 'Terminus',
        status: 'ACTIVE',
      );

      await tester.pumpWidget(createTestWidget(const TripCompletionScreen(trip: trip)));
      await tester.pumpAndSettle();

      expect(find.text('Trip Terminus & Layover'), findsOneWidget);
      expect(find.text('Corridor Trip: Aluva Metro Station ➔ Vyttila Mobility Hub'), findsOneWidget);
      expect(find.text('Complete Trip'), findsOneWidget);

      await tester.tap(find.text('Complete Trip'));
      await tester.pumpAndSettle();

      expect(find.text('Trip successfully marked as COMPLETED in central dispatch.'), findsOneWidget);
    });

    // 14. Conductor logout triggers auth state change
    testWidgets('14. Conductor logout triggers auth state change', (WidgetTester tester) async {
      setupScreen(tester);

      final authCtrl = MockAuthController(const Authenticated(conductorUser));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
            conductorRepositoryProvider.overrideWithValue(MockConductorRepository()),
            authControllerProvider.overrideWith((ref) => authCtrl),
          ],
          child: const MaterialApp(
            home: ConductorShell(user: conductorUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Out icon button
      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(authCtrl.state, const Unauthenticated());
    });

    // 15. Passenger flow remains unaffected
    testWidgets('15. Passenger flow remains unaffected', (WidgetTester tester) async {
      setupScreen(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
            conductorRepositoryProvider.overrideWithValue(MockConductorRepository()),
            authControllerProvider.overrideWith(
              (ref) => MockAuthController(const Authenticated(passengerUser)),
            ),
          ],
          child: const BusSenseApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PassengerShell), findsOneWidget);
      expect(find.text('PASSENGER'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
