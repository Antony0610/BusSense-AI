import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bussense_mobile/features/passenger/data/passenger_repository.dart';
import 'package:bussense_mobile/features/passenger/providers/passenger_providers.dart';
import 'package:bussense_mobile/features/passenger/views/ai_source_details_sheet.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_assistant_view.dart';
import 'package:bussense_mobile/features/passenger/views/passenger_shell.dart';
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

class MockAiPassengerRepository implements IPassengerRepository {
  final bool shouldFail;
  final bool returnActiveTicket;

  MockAiPassengerRepository({
    this.shouldFail = false,
    this.returnActiveTicket = true,
  });

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
  Future<PredictionModel> getBusPrediction(String busNumber) async {
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
      dataOrigin: 'PREDICTION',
    );
  }

  @override
  Future<JourneyPlanModel> getJourneyPlan({
    required String origin,
    required String destination,
  }) async {
    return const JourneyPlanModel(
      originStop: 'Kaloor',
      destinationStop: 'Vyttila',
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
        whyRecommended: 'Lower crowd and earlier arrival.',
        crowdSavingVsAlternativePct: 42.0,
        timeSavingMins: 5,
        fareInr: 25.0,
      ),
      alternativeBuses: [],
      routeDistanceKm: 14.8,
      estimatedTravelTimeMins: 28,
      explanation: 'Recommended based on low crowding.',
      dataOrigin: 'RECOMMENDATION',
    );
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
  }) async => sampleTicket;

  @override
  Future<List<TicketModel>> getMyTickets() async {
    if (returnActiveTicket) {
      return [sampleTicket];
    }
    return [];
  }

  @override
  Future<AIQueryResponse> askAiAssistant({
    required String question,
    String? activeBusContext,
    String? destinationContext,
    String? ticketId,
  }) async {
    if (shouldFail) {
      throw Exception('Service connection timeout');
    }

    final q = question.toLowerCase();

    if (q.contains('when will') || q.contains('arrive')) {
      return const AIQueryResponse(
        answer: 'Bus 205 (Fast Passenger) is currently near Kaloor and arrives at Palarivattom Jn in 4 minutes.',
        responseType: AIResponseType.liveData,
        sources: ['Live GPS Corridor Telemetry'],
        sourceItems: [
          AISourceItem(
            id: 'SRC-GPS',
            title: 'Live GPS Corridor Telemetry',
            sourceType: 'LIVE_DATA',
            snippet: 'Bus 205 ETA: 4 min at Palarivattom Jn.',
            reference: 'Corridor Dispatch Stream',
          )
        ],
        actions: [
          AIActionItem(label: 'View Bus Details', actionType: 'VIEW_BUS', payload: {'bus_number': '205'}),
          AIActionItem(label: 'Explore Routes', actionType: 'EXPLORE_ROUTES'),
        ],
        suggestedActions: ['Track Bus', 'Check Crowd'],
        dataOrigin: 'LIVE SENSOR TELEMETRY',
      );
    }

    if (q.contains('crowd') && q.contains('forecast')) {
      return const AIQueryResponse(
        answer: 'Crowd forecast for Bus 205: Now: 41.8%, +15 Min: 45.2%, +30 Min: 52.0%, +60 Min: 64.5%.',
        responseType: AIResponseType.prediction,
        sources: ['Ridge Regression 4-Horizon Demand Forecaster'],
        sourceItems: [
          AISourceItem(
            id: 'SRC-PRED',
            title: '4-Horizon Demand Prediction Model',
            sourceType: 'PREDICTION',
            snippet: '+15m: 45.2%, +30m: 52.0%, +60m: 64.5%',
            reference: 'BusSense Forecaster Engine',
          )
        ],
        actions: [
          AIActionItem(label: 'View Full Forecast', actionType: 'CROWD_FORECAST', payload: {'bus_number': '205'}),
        ],
        dataOrigin: 'MACHINE LEARNING PREDICTION',
      );
    }

    if (q.contains('recommend') || q.contains('which bus')) {
      return const AIQueryResponse(
        answer: 'Bus 205 is recommended because it has 40% lower crowding than Bus 14A and saves 12 minutes via the Banerji Road priority lane.',
        responseType: AIResponseType.recommendation,
        sources: ['BusSense AI Predictive Recommendation Engine'],
        sourceItems: [
          AISourceItem(
            id: 'SRC-REC',
            title: 'BusSense AI Multi-Factor Recommendation Engine',
            sourceType: 'RECOMMENDATION',
            snippet: 'Weighted scoring: 40% crowding delta, 35% corridor travel time.',
            reference: 'Corridor Dispatch Engine',
          )
        ],
        actions: [
          AIActionItem(label: 'Book Ticket on Bus 205', actionType: 'VIEW_BUS', payload: {'bus_number': '205'}),
        ],
        dataOrigin: 'MULTI-FACTOR RECOMMENDATION ENGINE',
      );
    }

    if (q.contains('my ticket') || q.contains('active ticket')) {
      return const AIQueryResponse(
        answer: 'You have an active digital boarding pass #BS-KL-2026-9281 for Bus 205 to Vyttila Mobility Hub. Status is VALID.',
        responseType: AIResponseType.ticketData,
        sources: ['User Ticket Store (Supabase PostgreSQL)'],
        sourceItems: [
          AISourceItem(
            id: 'SRC-TKT',
            title: 'Boarding Pass #BS-KL-2026-9281',
            sourceType: 'TICKET_DATA',
            snippet: 'Vehicle: Bus 205 • Route: Kaloor ➔ Vyttila • Status: VALID',
            reference: 'Supabase Ticket Store',
          )
        ],
        actions: [
          AIActionItem(label: 'Show Digital QR', actionType: 'SHOW_TICKET'),
          AIActionItem(label: 'Track Active Journey', actionType: 'TRACK_HUD'),
        ],
        dataOrigin: 'PERSISTENT POSTGRESQL TICKET STORE',
      );
    }

    if (q.contains('next stop') || q.contains('destination')) {
      return const AIQueryResponse(
        answer: 'You are traveling on Bus 205 towards Vyttila Mobility Hub. Next approaching stop is Palarivattom Jn in approximately 4 minutes.',
        responseType: AIResponseType.activeJourney,
        sources: ['Live GPS Corridor Telemetry'],
        sourceItems: [
          AISourceItem(
            id: 'SRC-HUD',
            title: 'Active Journey HUD Telemetry',
            sourceType: 'ACTIVE_JOURNEY',
            snippet: 'Bus 205: Approaching Palarivattom in 4 min.',
            reference: 'Corridor Dispatch Stream',
          )
        ],
        actions: [
          AIActionItem(label: 'Open Active Journey HUD', actionType: 'TRACK_HUD'),
        ],
        dataOrigin: 'LIVE SENSOR TELEMETRY & TRIP SCHEDULE',
      );
    }

    if (q.contains('france') || q.contains('stock')) {
      return const AIQueryResponse(
        answer: "I don't have enough reliable information to answer that yet. I am trained specifically on Greater Kochi transit corridors.",
        responseType: AIResponseType.insufficientInformation,
        sources: ['BusSense AI Verified Knowledge Boundary'],
        sourceItems: [
          AISourceItem(
            id: 'SRC-GUARD',
            title: 'Verified Knowledge Boundary',
            sourceType: 'KNOWLEDGE',
            snippet: 'Out-of-domain queries are declined.',
            reference: 'Safety Guardrails',
          )
        ],
        actions: [
          AIActionItem(label: 'Explore Routes', actionType: 'EXPLORE_ROUTES'),
        ],
        dataOrigin: 'SAFETY GUARDRAIL',
      );
    }

    // Default knowledge response
    return const AIQueryResponse(
      answer: 'BusSense AI estimates onboard crowding using a privacy-preserving YOLOv8 neural network. The system does NOT perform facial recognition.',
      responseType: AIResponseType.knowledge,
      sources: ['BusSense AI Computer Vision Architecture & Privacy Whitepaper'],
      sourceItems: [
        AISourceItem(
          id: 'SRC-KB',
          title: 'Computer Vision & Privacy Whitepaper',
          sourceType: 'KNOWLEDGE',
          snippet: 'Privacy-preserving YOLOv8 neural network without facial recognition.',
          reference: 'BusSense AI Whitepaper',
        )
      ],
      actions: [
        AIActionItem(label: 'Explore Routes', actionType: 'EXPLORE_ROUTES'),
      ],
      dataOrigin: 'VERIFIED KNOWLEDGE BASE',
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

  group('Phase H5 Batch 3 - AI Assistant & Grounded RAG Tests', () {
    testWidgets('1. AI screen renders header, starter prompts, and welcome card', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('BusSense AI'), findsWidgets);
      expect(find.text('Your journey assistant'), findsOneWidget);
      expect(find.text('RAG GROUNDED'), findsOneWidget);
      expect(find.text('Which bus is less crowded?'), findsOneWidget);
      expect(find.text('When will my bus arrive?'), findsOneWidget);
      expect(find.text('Ask about your journey...'), findsOneWidget);
    });

    testWidgets('2. Context bar renders active ticket info when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(returnActiveTicket: true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Active Context: Bus 205'), findsOneWidget);
      expect(find.text('Ask ETA'), findsOneWidget);
      expect(find.text('Next Stop'), findsOneWidget);
    });

    testWidgets('3. User message submission and response rendering', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'When will Bus 205 arrive?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('When will Bus 205 arrive?'), findsOneWidget);
      expect(find.textContaining('Palarivattom Jn in 4 minutes'), findsOneWidget);
      expect(find.text('LIVE DATA'), findsOneWidget);
      expect(find.text('LIVE SENSOR TELEMETRY'), findsOneWidget);
    });

    testWidgets('4. Prediction query renders prediction badge and 4-horizon trajectory', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'Show crowd forecast for Bus 205');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('PREDICTION'), findsOneWidget);
      expect(find.text('MACHINE LEARNING PREDICTION'), findsOneWidget);
      expect(find.textContaining('+15 Min: 45.2%'), findsOneWidget);
      expect(find.text('View Full Forecast'), findsOneWidget);
    });

    testWidgets('5. Recommendation query explains 3 factors and renders action', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'Which bus should I recommend?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('RECOMMENDATION'), findsOneWidget);
      expect(find.textContaining('40% lower crowding'), findsOneWidget);
      expect(find.text('Book Ticket on Bus 205'), findsOneWidget);
    });

    testWidgets('6. Ticket query renders authenticated ticket data and actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'Show my active ticket');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('TICKET DATA'), findsOneWidget);
      expect(find.textContaining('BS-KL-2026-9281'), findsOneWidget);
      expect(find.text('Show Digital QR'), findsOneWidget);
      expect(find.text('Track Active Journey'), findsOneWidget);
    });

    testWidgets('7. Active journey query renders next stop and HUD CTA', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'What is my next stop?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE JOURNEY'), findsOneWidget);
      expect(find.textContaining('Palarivattom Jn'), findsOneWidget);
      expect(find.text('Open Active Journey HUD'), findsOneWidget);
    });

    testWidgets('8. Insufficient information query triggers safe fallback without hallucination', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'What is the capital of France?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('INSUFFICIENT INFO'), findsOneWidget);
      expect(find.textContaining("I don't have enough reliable information to answer that yet"), findsOneWidget);
      expect(find.text('SAFETY GUARDRAIL'), findsOneWidget);
    });

    testWidgets('9. Tapping source citations button opens AISourceDetailsSheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'How does camera privacy work?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final sourceButton = find.textContaining('Verified Sources').first;
      expect(sourceButton, findsOneWidget);
      await tester.ensureVisible(sourceButton);
      await tester.pumpAndSettle();
      await tester.tap(sourceButton);
      await tester.pumpAndSettle();

      expect(find.byType(AISourceDetailsSheet), findsOneWidget);
      expect(find.text('Source Citations & Provenance'), findsOneWidget);
      expect(find.text('Data Origin & Provenance'), findsOneWidget);
    });

    testWidgets('10. Error state renders when network/server fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerAssistantView(),
          repository: MockAiPassengerRepository(shouldFail: true),
        ),
      );

      await tester.pumpAndSettle();

      final input = find.byType(TextFormField);
      await tester.enterText(input, 'When will bus arrive?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('BusSense AI is temporarily unable to retrieve transit information'), findsOneWidget);
    });

    testWidgets('11. PassengerShell navigation switches to AI tab cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          child: const PassengerShell(user: testUser),
          repository: MockAiPassengerRepository(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on AI tab
      await tester.tap(find.text('AI'));
      await tester.pumpAndSettle();

      expect(find.byType(PassengerAssistantView), findsOneWidget);
      expect(find.text('Your journey assistant'), findsOneWidget);
    });
  });
}
