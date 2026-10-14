import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/features/passenger/data/passenger_repository.dart';
import 'package:bussense_mobile/features/passenger/providers/passenger_providers.dart';
import 'package:bussense_mobile/features/passenger/views/active_journey_screen.dart';
import 'package:bussense_mobile/features/passenger/views/booking_review_screen.dart';
import 'package:bussense_mobile/features/passenger/views/digital_qr_ticket_screen.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_shell.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_tickets_view.dart';
import 'package:bussense_mobile/features/passenger/views/test_payment_screen.dart';
import 'package:bussense_mobile/features/passenger/views/ticket_booking_screen.dart';
import 'package:bussense_mobile/shared/models/ai_message_model.dart';
import 'package:bussense_mobile/shared/models/alert_model.dart';
import 'package:bussense_mobile/shared/models/bus_model.dart';
import 'package:bussense_mobile/shared/models/crowd_model.dart';
import 'package:bussense_mobile/shared/models/location_model.dart';
import 'package:bussense_mobile/shared/models/prediction_model.dart';
import 'package:bussense_mobile/shared/models/recommendation_model.dart';
import 'package:bussense_mobile/shared/models/passenger_report_model.dart';
import 'package:bussense_mobile/shared/models/saved_place_model.dart';
import 'package:bussense_mobile/shared/models/ticket_model.dart';
import 'package:bussense_mobile/shared/models/trip_model.dart';
import 'package:bussense_mobile/shared/models/user_model.dart';
import 'package:bussense_mobile/shared/models/user_preferences_model.dart';
import 'package:bussense_mobile/shared/models/notification_item_model.dart';

class MockTicketingRepository implements IPassengerRepository {
  final bool shouldFail;
  final bool returnEmpty;

  MockTicketingRepository({this.shouldFail = false, this.returnEmpty = false});

  static const sampleBus205 = BusModel(
    busId: 'bus-205',
    busNumber: '205',
    registrationNumber: 'KL-15-A-2051',
    operatorType: 'KSRTC',
    routeNumber: '12',
    routeName: 'Aluva Metro ➔ Vyttila Mobility Hub via Kaloor',
    capacity: 55,
    passengerCount: 23,
    occupancyPct: 41.8,
    crowdLevel: CrowdLevel.low,
    speedKmh: 42.5,
    headingDeg: 195.0,
    latitude: 9.9816,
    longitude: 76.3031,
    currentStop: 'Kaloor Metro Stand',
    nextStop: 'Palarivattom Jn',
    etaNextStopMins: 4,
    dataOrigin: 'SIMULATED DATA',
  );

  static const sampleTicket = TicketModel(
    id: 'tk-101',
    ticketNumber: 'BS-KL-2026-9281',
    passengerName: 'Ananya Sharma',
    busNumber: '205',
    routeNumber: '12',
    originStop: 'Kaloor Metro Stand',
    destinationStop: 'Vyttila Mobility Hub',
    fareAmount: 25.0,
    finalFare: 25.0,
    status: 'VALID',
    qrCodeHash: 'bussense://ticket/BS-KL-2026-9281',
    qrCodeDataUri: '',
    validFrom: '2026-09-27T10:00:00Z',
    validUntil: '2026-09-27T14:00:00Z',
    createdAt: '2026-09-27T10:00:00Z',
    dataOrigin: 'LIVE DATA',
  );

  @override
  Future<List<BusModel>> getLiveBuses() async => [sampleBus205];

  @override
  Future<BusModel> getBusDetails(String busNumber) async => sampleBus205;

  @override
  Future<List<LocationModel>> getLiveLocations() async => [];

  @override
  Future<LocationModel?> getBusLocation(String busIdentifier) async => null;

  @override
  Future<List<CrowdModel>> getFleetCrowd() async => [];

  @override
  Future<CrowdModel?> getBusCrowd(String busIdentifier) async => null;

  @override
  Future<PredictionModel> getBusPrediction(String busNumber) async => const PredictionModel(
        busNumber: '205',
        routeNumber: '12',
        corridorName: 'Aluva - Vyttila',
        nowOccupancyPct: 41.8,
        plus15mOccupancyPct: 45.2,
        plus30mOccupancyPct: 52.0,
        plus60mOccupancyPct: 64.5,
      );

  @override
  Future<JourneyPlanModel> getJourneyPlan({required String origin, required String destination}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AlertModel>> getActiveAlerts() async => [];

  @override
  Future<List<TripModel>> getActiveTrips() async => [];

  @override
  Future<TicketModel> bookTicket({
    required String busNumber,
    required String routeNumber,
    required String originStop,
    required String destinationStop,
    required String passengerName,
    required double fareAmount,
    String? tripId,
    String paymentMethod = 'SIMULATED_UPI',
  }) async {
    if (shouldFail) throw Exception('Payment Gateway Error');
    return sampleTicket;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    if (shouldFail) throw Exception('Database error');
    if (returnEmpty) return [];
    return [sampleTicket];
  }

  @override
  Future<AIQueryResponse> askAiAssistant({
    required String question,
    String? activeBusContext,
    String? destinationContext,
    String? ticketId,
  }) async {
    if (shouldFail) throw Exception('AI Assistant error');
    return const AIQueryResponse(
      answer: 'Based on real-time telemetry, Bus 205 arrives in 4 minutes.',
      responseType: AIResponseType.liveData,
      sources: ['Live GPS Telemetry'],
      sourceItems: [
        AISourceItem(
          id: 'SRC-GPS',
          title: 'Live GPS Telemetry',
          sourceType: 'LIVE_DATA',
          snippet: 'Bus 205 is approaching Kaloor Metro Station.',
          reference: 'Corridor Telemetry',
        )
      ],
      actions: [
        AIActionItem(label: 'Track Bus', actionType: 'TRACK_HUD'),
      ],
      suggestedActions: ['Track Bus', 'Check Crowd'],
      dataOrigin: 'LIVE SENSOR TELEMETRY',
    );
  }

  @override
  Future<UserModel> getUserProfile() async => const UserModel(
        id: 'u-1',
        email: 'commuter@bussense.ai',
        fullName: 'Ananya Sharma',
        role: UserRole.passenger,
      );

  @override
  Future<UserModel> updateUserProfile({required String fullName, String? preferredLanguage}) async =>
      UserModel(
        id: 'u-1',
        email: 'commuter@bussense.ai',
        fullName: fullName,
        role: UserRole.passenger,
        preferredLanguage: preferredLanguage ?? 'en',
      );

  @override
  Future<List<SavedPlaceModel>> getSavedPlaces() async => [];

  @override
  Future<SavedPlaceModel> addSavedPlace(SavedPlaceModel place) async => place;

  @override
  Future<void> deleteSavedPlace(String placeId) async {}

  @override
  Future<UserPreferencesModel> getUserPreferences() async => const UserPreferencesModel();

  @override
  Future<UserPreferencesModel> updateUserPreferences(UserPreferencesModel preferences) async =>
      preferences;

  @override
  Future<PassengerReportModel> submitPassengerReport(PassengerReportModel report) async => report;

  @override
  Future<Map<String, dynamic>> exportUserData() async => {'status': 'OK', 'user_id': 'u-1'};

  @override
  Future<void> deactivateAccount() async {}

  @override
  Future<List<NotificationItemModel>> getNotifications({bool unreadOnly = false, int limit = 20, int offset = 0}) async => [];

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<bool> markNotificationRead(String notificationId) async => true;

  @override
  Future<int> markAllNotificationsRead() async => 0;
}

void main() {
  const testUser = UserModel(
    id: 'u-1',
    email: 'commuter@bussense.ai',
    fullName: 'Ananya Sharma',
    role: UserRole.passenger,
  );

  Widget createWidget({
    required Widget child,
    IPassengerRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        if (repository != null)
          passengerRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Phase H5 Batch 2 - Ticketing & Active Journey Tests', () {
    testWidgets('1. Booking entry renders selected journey and bus details', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const TicketBookingScreen(
            bus: MockTicketingRepository.sampleBus205,
            initialOrigin: 'Kaloor Metro Stand',
            initialDestination: 'Vyttila Mobility Hub',
            initialFare: 25.0,
          ),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Book Boarding Pass'), findsOneWidget);
      expect(find.text('205'), findsOneWidget);
      expect(find.text('Aluva Metro ➔ Vyttila Mobility Hub via Kaloor'), findsOneWidget);
      expect(find.text('Kaloor Metro Stand'), findsOneWidget);
      expect(find.text('Vyttila Mobility Hub'), findsOneWidget);
      expect(find.text('₹25'), findsOneWidget);
    });

    testWidgets('2. Fare and passenger input fields render and validate', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const TicketBookingScreen(
            bus: MockTicketingRepository.sampleBus205,
          ),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Clear passenger name and tap continue to trigger validation
      final nameField = find.byType(TextFormField).at(2);
      await tester.enterText(nameField, '');
      await tester.ensureVisible(find.text('Continue to Review'));
      await tester.tap(find.text('Continue to Review'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter passenger name'), findsOneWidget);
    });

    testWidgets('3. Booking review renders journey summary before payment', (WidgetTester tester) async {
      const draft = BookingDraft(
        busNumber: '205',
        routeNumber: '12',
        routeName: 'Aluva Metro ➔ Vyttila Mobility Hub',
        operatorType: 'KSRTC',
        originStop: 'Kaloor Metro Stand',
        destinationStop: 'Vyttila Mobility Hub',
        passengerName: 'Ananya Sharma',
        fareAmount: 25.0,
      );

      await tester.pumpWidget(
        createWidget(
          child: const BookingReviewScreen(draft: draft),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Booking Review'), findsOneWidget);
      expect(find.text('BEFORE PAYMENT'), findsOneWidget);
      expect(find.text('Kaloor Metro Stand'), findsOneWidget);
      expect(find.text('Vyttila Mobility Hub'), findsOneWidget);
      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('₹25'), findsWidgets);
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('4. Test payment screen renders amount and processes simulated success', (WidgetTester tester) async {
      const draft = BookingDraft(
        busNumber: '205',
        routeNumber: '12',
        routeName: 'Aluva Metro ➔ Vyttila Hub',
        operatorType: 'KSRTC',
        originStop: 'Kaloor Metro Stand',
        destinationStop: 'Vyttila Mobility Hub',
        passengerName: 'Ananya Sharma',
        fareAmount: 25.0,
      );

      await tester.pumpWidget(
        createWidget(
          child: const TestPaymentScreen(draft: draft),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payment Gateway'), findsOneWidget);
      expect(find.text('SIMULATED PAYMENT'), findsOneWidget);
      expect(find.text('₹25.00'), findsOneWidget);

      // Tap simulate success payment
      await tester.ensureVisible(find.text('Pay ₹25 (Simulate Success)'));
      await tester.tap(find.text('Pay ₹25 (Simulate Success)'));
      await tester.pumpAndSettle();

      // Successfully transitioned to Digital QR Ticket
      expect(find.byType(DigitalQrTicketScreen), findsOneWidget);
      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.text('BS-KL-2026-9281'), findsOneWidget);
    });

    testWidgets('5. Test payment handles simulated failure and error state', (WidgetTester tester) async {
      const draft = BookingDraft(
        busNumber: '205',
        routeNumber: '12',
        routeName: 'Aluva Metro ➔ Vyttila Hub',
        operatorType: 'KSRTC',
        originStop: 'Kaloor Metro Stand',
        destinationStop: 'Vyttila Mobility Hub',
        passengerName: 'Ananya Sharma',
        fareAmount: 25.0,
      );

      await tester.pumpWidget(
        createWidget(
          child: const TestPaymentScreen(draft: draft),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap simulate failure
      await tester.ensureVisible(find.text('Simulate Payment Failure'));
      await tester.tap(find.text('Simulate Payment Failure'));
      await tester.pumpAndSettle();

      expect(find.text('Payment Failed'), findsOneWidget);
      expect(find.textContaining('Simulated Payment Gateway Decline'), findsOneWidget);
    });

    testWidgets('6. Digital QR Ticket renders ticket ID and QR code', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const DigitalQrTicketScreen(ticket: MockTicketingRepository.sampleTicket),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Digital Boarding Pass'), findsOneWidget);
      expect(find.text('BS-KL-2026-9281'), findsOneWidget);
      expect(find.text('Scan with Conductor Terminal'), findsOneWidget);
      expect(find.text('Track Active Journey HUD'), findsOneWidget);
    });

    testWidgets('7. Active Journey HUD renders glanceable bus, next stop, and ETA', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const ActiveJourneyScreen(ticket: MockTicketingRepository.sampleTicket),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Journey HUD'), findsOneWidget);
      expect(find.text('CURRENT BUS'), findsOneWidget);
      expect(find.text('205'), findsWidgets);
      expect(find.text('YOUR DESTINATION'), findsOneWidget);
      expect(find.text('Vyttila Mobility Hub'), findsWidgets);
      expect(find.text('NEXT APPROACHING STOP'), findsOneWidget);
      expect(find.text('Palarivattom Jn'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.text('ETA'), findsOneWidget);
      expect(find.text('Route Progress'), findsOneWidget);
    });

    testWidgets('8. Active Journey renders empty state when no ticket active', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const ActiveJourneyScreen(ticket: null),
          repository: MockTicketingRepository(returnEmpty: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Journey'), findsOneWidget);
      expect(find.text('Explore Routes'), findsOneWidget);
    });

    testWidgets('9. PassengerTicketsView renders active ticket and action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: PassengerTicketsView(onExploreRoutes: () {}),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Active Boarding Pass'), findsOneWidget);
      expect(find.text('Show QR'), findsOneWidget);
      expect(find.text('Track HUD'), findsOneWidget);
      expect(find.textContaining('BS-KL-2026-9281'), findsOneWidget);
    });

    testWidgets('10. PassengerTicketsView renders empty state when no tickets booked', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: PassengerTicketsView(onExploreRoutes: () {}),
          repository: MockTicketingRepository(returnEmpty: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Digital Tickets'), findsOneWidget);
      expect(find.text('Explore Corridor Routes'), findsOneWidget);
    });

    testWidgets('11. PassengerShell navigation switches to Tickets tab cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerShell(user: testUser),
          repository: MockTicketingRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Tickets
      await tester.tap(find.text('Tickets'));
      await tester.pumpAndSettle();

      expect(find.text('Digital Tickets'), findsWidgets);
      expect(find.text('Active Boarding Pass'), findsOneWidget);
    });
  });
}
