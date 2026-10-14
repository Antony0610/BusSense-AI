import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/features/passenger/data/passenger_repository.dart';
import 'package:bussense_mobile/features/passenger/providers/passenger_providers.dart';
import 'package:bussense_mobile/features/passenger/views/bus_details_screen.dart';
import 'package:bussense_mobile/features/passenger/views/crowd_forecast_screen.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_explore_view.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_home_view.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_live_map_view.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_shell.dart';
import 'package:bussense_mobile/features/passenger/views/smart_recommendation_screen.dart';
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

/// Test mock implementation for isolated widget tests
class MockPassengerRepository implements IPassengerRepository {
  final bool shouldFail;
  final bool returnEmpty;

  MockPassengerRepository({this.shouldFail = false, this.returnEmpty = false});

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

  static const sampleBus14A = BusModel(
    busId: 'bus-14a',
    busNumber: '14A',
    registrationNumber: 'KL-07-CF-1402',
    operatorType: 'PRIVATE',
    routeNumber: '14A',
    routeName: 'Fort Kochi ➔ Infopark Phase 1',
    capacity: 45,
    passengerCount: 38,
    occupancyPct: 84.4,
    crowdLevel: CrowdLevel.crowded,
    speedKmh: 28.0,
    headingDeg: 85.0,
    latitude: 9.9703,
    longitude: 76.2487,
    currentStop: 'Fort Kochi Boat Jetty',
    nextStop: 'MG Road North',
    etaNextStopMins: 9,
    dataOrigin: 'SIMULATED DATA',
  );

  @override
  Future<List<BusModel>> getLiveBuses() async {
    if (shouldFail) throw Exception('Simulated Network Outage');
    if (returnEmpty) return [];
    return [sampleBus205, sampleBus14A];
  }

  @override
  Future<BusModel> getBusDetails(String busNumber) async {
    if (shouldFail) throw Exception('Bus not found');
    return sampleBus205;
  }

  @override
  Future<List<LocationModel>> getLiveLocations() async {
    if (shouldFail) throw Exception('GPS simulation unavailable');
    if (returnEmpty) return [];
    return [
      const LocationModel(
        busId: 'bus-205',
        busNumber: '205',
        registrationNumber: 'KL-15-A-2051',
        latitude: 9.9816,
        longitude: 76.3031,
        speedKmh: 42.5,
        headingDeg: 195.0,
        currentStop: 'Kaloor Metro',
        nextStop: 'Palarivattom',
        etaNextStopMins: 4,
        timestamp: '2026-09-27T10:00:00Z',
      ),
    ];
  }

  @override
  Future<LocationModel?> getBusLocation(String busIdentifier) async => null;

  @override
  Future<List<CrowdModel>> getFleetCrowd() async => [];

  @override
  Future<CrowdModel?> getBusCrowd(String busIdentifier) async => null;

  @override
  Future<PredictionModel> getBusPrediction(String busNumber) async {
    if (shouldFail) throw Exception('Prediction model offline');
    return const PredictionModel(
      busNumber: '205',
      routeNumber: '12',
      corridorName: 'Aluva - Vyttila Corridor',
      nowOccupancyPct: 41.8,
      plus15mOccupancyPct: 45.2,
      plus30mOccupancyPct: 52.0,
      plus60mOccupancyPct: 64.5,
      nowCrowdLevel: CrowdLevel.low,
      plus15mCrowdLevel: CrowdLevel.low,
      plus30mCrowdLevel: CrowdLevel.moderate,
      plus60mCrowdLevel: CrowdLevel.moderate,
      confidenceScore: 0.88,
      modelVersion: 'xgboost-demand-v1',
      dataOrigin: 'PREDICTION',
    );
  }

  @override
  Future<JourneyPlanModel> getJourneyPlan({
    required String origin,
    required String destination,
  }) async {
    if (shouldFail) throw Exception('Recommendation engine failure');
    return const JourneyPlanModel(
      originStop: 'Kaloor Metro Station, Kochi',
      destinationStop: 'Vyttila Mobility Hub',
      recommendedBus: BusRecommendationItem(
        busNumber: '205',
        routeNumber: '12',
        routeName: 'Aluva Metro ➔ Vyttila Mobility Hub',
        operatorType: 'KSRTC',
        etaMins: 4,
        occupancyPct: 41.8,
        crowdLevel: CrowdLevel.low,
        isRecommended: true,
        journeyScore: 84.5,
        whyRecommended: 'Lower crowd (42% vs 84%) and earlier arrival by 5 mins.',
        crowdSavingVsAlternativePct: 42.0,
        timeSavingMins: 5,
        fareInr: 25.0,
      ),
      alternativeBuses: [
        BusRecommendationItem(
          busNumber: '14A',
          routeNumber: '14A',
          routeName: 'Fort Kochi ➔ Infopark Phase 1',
          operatorType: 'PRIVATE',
          etaMins: 9,
          occupancyPct: 84.4,
          crowdLevel: CrowdLevel.crowded,
          isRecommended: false,
          journeyScore: 52.0,
          whyRecommended: 'High passenger density, standing room only.',
          fareInr: 22.0,
        ),
      ],
      routeDistanceKm: 14.8,
      estimatedTravelTimeMins: 28,
      explanation: 'We recommend Bus 205 because it arrives in 4 minutes with low crowding.',
    );
  }

  @override
  Future<List<AlertModel>> getActiveAlerts() async {
    if (shouldFail || returnEmpty) return [];
    return [
      const AlertModel(
        id: 'alt-1',
        title: 'Metro Feeder Priority Lane Active',
        message: 'Buses operating on dedicated Banerji Road corridor.',
        severity: 'INFO',
        affectedRoute: 'Route 205',
        isActive: true,
        createdAt: '2026-09-27T08:00:00Z',
      ),
    ];
  }

  @override
  Future<List<TripModel>> getActiveTrips() async => [];

  static const sampleTicket = TicketModel(
    id: 'tk-1',
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
    if (shouldFail) throw Exception('Booking failed');
    return sampleTicket;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    if (shouldFail) throw Exception('Unable to load tickets');
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
  const testPassenger = UserModel(
    id: 'user-p1',
    email: 'commuter@bussense.ai',
    fullName: 'Ananya Sharma',
    role: UserRole.passenger,
  );

  Widget createTestWidget({
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

  group('Phase H5 Batch 1 - Passenger Home Tests', () {
    testWidgets('1. Passenger Home displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerHomeView(
            user: testPassenger,
            onNavigateToExplore: _dummyCallback,
          ),
          repository: MockPassengerRepository(),
        ),
      );

      expect(find.byType(PassengerHomeView), findsOneWidget);
      expect(find.text('Where are you going?'), findsOneWidget);
    });

    testWidgets('2. Passenger Home displays live departures on API success', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerHomeView(
            user: testPassenger,
            onNavigateToExplore: _dummyCallback,
          ),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user identity & hero
      expect(find.text('Ananya Sharma'), findsOneWidget);
      expect(find.text('Where are you going?'), findsOneWidget);

      // Verify live buses rendered from mock repository
      expect(find.text('205'), findsOneWidget);
      expect(find.text('14A'), findsOneWidget);
      expect(find.text('Live Departures'), findsOneWidget);
      expect(find.text('SIMULATED DATA'), findsWidgets);

      // Verify crowd labels and ETAs
      expect(find.text('4 min'), findsOneWidget);
      expect(find.text('9 min'), findsOneWidget);
    });

    testWidgets('3. Passenger Home displays error state on API failure', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerHomeView(
            user: testPassenger,
            onNavigateToExplore: _dummyCallback,
          ),
          repository: MockPassengerRepository(shouldFail: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Telemetry Offline'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('4. Passenger Home displays empty state when no buses active', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerHomeView(
            user: testPassenger,
            onNavigateToExplore: _dummyCallback,
          ),
          repository: MockPassengerRepository(returnEmpty: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Buses in Corridor'), findsOneWidget);
    });
  });

  group('Phase H5 Batch 1 - Explore & Route Planning Tests', () {
    testWidgets('5. Explore screen renders origin/destination search & journey recommendations', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerExploreView(),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Inputs
      expect(find.text('Starting Stop / Origin'), findsOneWidget);
      expect(find.text('Destination Stop'), findsOneWidget);
      expect(find.text('Search Available Buses'), findsOneWidget);

      // Recommended Hero
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
      expect(find.text('205'), findsWidgets);
      expect(find.text('42% lower crowd'), findsOneWidget);

      // Corridor Alternatives
      expect(find.text('Corridor Alternatives'), findsOneWidget);
      expect(find.text('14A'), findsWidgets);
    });
  });

  group('Phase H5 Batch 1 - Bus Details Tests', () {
    testWidgets('6. Bus Details screen renders full profile and occupancy progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const BusDetailsScreen(bus: MockPassengerRepository.sampleBus205),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Header and Route
      expect(find.text('Bus 205'), findsWidgets);
      expect(find.text('Aluva Metro ➔ Vyttila Mobility Hub via Kaloor'), findsOneWidget);
      expect(find.text('KSRTC • Reg: KL-15-A-2051'), findsOneWidget);

      // ETA & Occupancy
      expect(find.text('4'), findsWidgets);
      expect(find.text('Cabin Occupancy'), findsOneWidget);
      expect(find.text('41.8% Capacity'), findsOneWidget);
      expect(find.text('23 / 55 Passengers'), findsOneWidget);

      // Action buttons
      expect(find.text('View Crowd Forecast (4 Horizons)'), findsOneWidget);
      expect(find.text('Smart Journey Recommendations'), findsOneWidget);
    });
  });

  group('Phase H5 Batch 1 - Crowd Forecast Tests', () {
    testWidgets('7. Crowd Forecast renders 4 forward prediction horizons with honesty badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const CrowdForecastScreen(busNumber: '205'),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Crowd Forecast'), findsOneWidget);
      expect(find.text('Bus 205 • 4-Horizon Trajectory'), findsOneWidget);

      // 4 Horizons
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('+15 MIN'), findsOneWidget);
      expect(find.text('+30 MIN'), findsOneWidget);
      expect(find.text('+60 MIN'), findsOneWidget);

      // Honesty badges
      expect(find.text('LIVE DATA'), findsOneWidget);
      expect(find.text('PREDICTION'), findsWidgets);
      expect(find.text('DATA DISCLOSURE & PROTOTYPE NOTICE'), findsOneWidget);
    });
  });

  group('Phase H5 Batch 1 - Smart Recommendation Tests', () {
    testWidgets('8. Smart Recommendation screen renders backend explainability factors', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const SmartRecommendationScreen(busNumber: '205', routeName: 'Aluva - Vyttila'),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Smart Recommendation'), findsOneWidget);
      expect(find.text('RECOMMENDED FOR YOU'), findsOneWidget);
      expect(find.text('Why this bus?'), findsOneWidget);
      expect(find.text('42% lower crowding compared to alternative'), findsOneWidget);
      expect(find.text('Saves 5 minutes via priority corridor'), findsOneWidget);
      expect(find.text('RECOMMENDATION RATIONALE'), findsOneWidget);
      expect(find.text('Alternative Options Evaluated'), findsOneWidget);
    });
  });

  group('Phase H5 Batch 1 - Shell Integration Tests', () {
    testWidgets('9. PassengerShell switches seamlessly between Home, Explore and placeholders', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerShell(user: testPassenger),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially on Home
      expect(find.text('Live Departures'), findsWidgets);
      expect(find.text('Where are you going?'), findsOneWidget);

      // Switch to Explore
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Explore Corridors'), findsWidgets);
      expect(find.text('Search Available Buses'), findsOneWidget);

      // Switch to Tickets (now functional digital tickets view)
      await tester.tap(find.text('Tickets'));
      await tester.pumpAndSettle();
      expect(find.text('Digital Tickets'), findsWidgets);
      expect(find.text('Active Boarding Pass'), findsOneWidget);

      // Switch to AI (functional BusSense AI Assistant)
      await tester.tap(find.text('AI'));
      await tester.pumpAndSettle();
      expect(find.text('BusSense AI'), findsWidgets);
      expect(find.text('Your journey assistant'), findsOneWidget);
    });

    testWidgets('10. Live Map view loads and displays vehicle markers', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerLiveMapView(),
          repository: MockPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Live Fleet Map'), findsOneWidget);
      expect(find.textContaining('SIMULATED GPS TELEMETRY'), findsOneWidget);
      expect(find.text('205'), findsWidgets);
    });
  });
}

void _dummyCallback() {}
