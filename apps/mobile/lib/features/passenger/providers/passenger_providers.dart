import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/passenger_repository.dart';
import '../../../core/network/realtime_client.dart';
import '../../../shared/models/ai_message_model.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/crowd_model.dart';
import '../../../shared/models/location_model.dart';
import '../../../shared/models/notification_item_model.dart';
import '../../../shared/models/passenger_report_model.dart';
import '../../../shared/models/prediction_model.dart';
import '../../../shared/models/recommendation_model.dart';
import '../../../shared/models/saved_place_model.dart';
import '../../../shared/models/ticket_model.dart';
import '../../../shared/models/trip_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/user_preferences_model.dart';

/// Provider for Passenger Repository
final passengerRepositoryProvider = Provider<IPassengerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PassengerRepository(apiClient);
});

/// Live Buses & Fleet Departures Provider
final liveBusesProvider = FutureProvider<List<BusModel>>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getLiveBuses();
});

/// Live Vehicle Locations for GPS Map
final liveLocationsProvider = FutureProvider<List<LocationModel>>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getLiveLocations();
});

/// Fleet Crowd Density Provider
final fleetCrowdProvider = FutureProvider<List<CrowdModel>>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getFleetCrowd();
});

/// Active Public Service Alerts Provider
final activeAlertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getActiveAlerts();
});

/// Active Corridor Trips Provider
final activeTripsProvider = FutureProvider<List<TripModel>>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getActiveTrips();
});

/// Currently Selected Bus (for Map inspection & Details navigation)
final selectedBusProvider = StateProvider<BusModel?>((ref) => null);

/// 4-Horizon Demand Prediction Provider by Bus Number
final busPredictionProvider = FutureProvider.family<PredictionModel, String>((ref, busNumber) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getBusPrediction(busNumber);
});

/// Explore Journey Query Parameters (Origin & Destination)
class JourneyQuery {
  final String origin;
  final String destination;

  const JourneyQuery({
    required this.origin,
    required this.destination,
  });

  JourneyQuery copyWith({
    String? origin,
    String? destination,
  }) {
    return JourneyQuery(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyQuery &&
          runtimeType == other.runtimeType &&
          origin == other.origin &&
          destination == other.destination;

  @override
  int get hashCode => origin.hashCode ^ destination.hashCode;
}

final journeyQueryProvider = StateProvider<JourneyQuery>((ref) {
  return const JourneyQuery(
    origin: 'Kaloor Metro Station, Kochi',
    destination: 'Vyttila Mobility Hub',
  );
});

/// Journey Plan Recommendation Provider
final journeyPlanProvider = FutureProvider<JourneyPlanModel>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  final query = ref.watch(journeyQueryProvider);
  return repository.getJourneyPlan(
    origin: query.origin,
    destination: query.destination,
  );
});

/// In-Flight Commuter Booking Draft (BOOK -> REVIEW -> PAY)
class BookingDraft {
  final String busNumber;
  final String routeNumber;
  final String routeName;
  final String operatorType;
  final String originStop;
  final String destinationStop;
  final String passengerName;
  final double fareAmount;
  final String? tripId;
  final int etaMins;
  final CrowdLevel crowdLevel;

  const BookingDraft({
    required this.busNumber,
    required this.routeNumber,
    required this.routeName,
    required this.operatorType,
    required this.originStop,
    required this.destinationStop,
    required this.passengerName,
    required this.fareAmount,
    this.tripId,
    this.etaMins = 5,
    this.crowdLevel = CrowdLevel.low,
  });

  BookingDraft copyWith({
    String? busNumber,
    String? routeNumber,
    String? routeName,
    String? operatorType,
    String? originStop,
    String? destinationStop,
    String? passengerName,
    double? fareAmount,
    String? tripId,
    int? etaMins,
    CrowdLevel? crowdLevel,
  }) {
    return BookingDraft(
      busNumber: busNumber ?? this.busNumber,
      routeNumber: routeNumber ?? this.routeNumber,
      routeName: routeName ?? this.routeName,
      operatorType: operatorType ?? this.operatorType,
      originStop: originStop ?? this.originStop,
      destinationStop: destinationStop ?? this.destinationStop,
      passengerName: passengerName ?? this.passengerName,
      fareAmount: fareAmount ?? this.fareAmount,
      tripId: tripId ?? this.tripId,
      etaMins: etaMins ?? this.etaMins,
      crowdLevel: crowdLevel ?? this.crowdLevel,
    );
  }
}

final currentBookingDraftProvider = StateProvider<BookingDraft?>((ref) => null);

/// Commuter's Digital Boarding Passes Provider
final myTicketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getMyTickets();
});

/// Latest Active/Valid Digital Boarding Pass
final activeTicketProvider = Provider<TicketModel?>((ref) {
  final tickets = ref.watch(myTicketsProvider).valueOrNull ?? [];
  for (final t in tickets) {
    if (t.status == 'VALID' || t.status == 'BOOKED') {
      return t;
    }
  }
  return tickets.isNotEmpty ? tickets.first : null;
});

/// Active Journey HUD Current Selected Ticket
final activeJourneyTicketProvider = StateProvider<TicketModel?>((ref) => null);

/// AI Assistant Loading State
final aiLoadingProvider = StateProvider<bool>((ref) => false);

/// AI Assistant Error Message
final aiErrorProvider = StateProvider<String?>((ref) => null);

/// AI Suggested Transit Questions
final suggestedPromptsProvider = Provider<List<String>>((ref) {
  return const [
    'Which bus is less crowded?',
    'When will my bus arrive?',
    'How do I get to Vyttila?',
    'Show my active ticket',
    'What does crowd level mean?',
    'Why was this bus recommended?',
  ];
});

/// Conversational Chat State Notifier
class AIChatNotifier extends StateNotifier<List<ChatMessage>> {
  final IPassengerRepository _repository;
  final Ref _ref;

  AIChatNotifier(this._repository, this._ref) : super([
    ChatMessage(
      id: 'msg-welcome',
      text: 'Hello! I am BusSense AI, your Kochi transit companion. Ask me about live bus arrival times, cabin crowd levels, smart recommendations, or your active digital ticket.',
      isUser: false,
      timestamp: DateTime.now(),
      responseType: AIResponseType.knowledge,
      sources: const ['BusSense AI Transit Intelligence Platform'],
      sourceItems: const [
        AISourceItem(
          id: 'SRC-INIT',
          title: 'BusSense AI Platform Overview',
          sourceType: 'KNOWLEDGE',
          snippet: 'Grounded transit assistant for Greater Kochi bus operations.',
          reference: 'Platform Architecture',
        )
      ],
      actions: const [
        AIActionItem(label: 'Explore Routes', actionType: 'EXPLORE_ROUTES'),
      ],
      dataOrigin: 'VERIFIED KNOWLEDGE BASE',
    )
  ]);

  Future<void> sendQuery(
    String query, {
    String? activeBus,
    String? destination,
    String? ticketId,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // 1. Append user message
    final userMsg = ChatMessage(
      id: 'msg-user-${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    _ref.read(aiLoadingProvider.notifier).state = true;
    _ref.read(aiErrorProvider.notifier).state = null;

    try {
      final res = await _repository.askAiAssistant(
        question: trimmed,
        activeBusContext: activeBus,
        destinationContext: destination,
        ticketId: ticketId,
      );

      final aiMsg = ChatMessage(
        id: 'msg-ai-${DateTime.now().millisecondsSinceEpoch}',
        text: res.answer,
        isUser: false,
        timestamp: DateTime.now(),
        responseType: res.responseType,
        sources: res.sources,
        sourceItems: res.sourceItems,
        actions: res.actions,
        dataOrigin: res.dataOrigin,
      );

      state = [...state, aiMsg];
    } catch (e) {
      _ref.read(aiErrorProvider.notifier).state = e.toString();
      final errorMsg = ChatMessage(
        id: 'msg-err-${DateTime.now().millisecondsSinceEpoch}',
        text: 'BusSense AI is temporarily unable to retrieve transit information. Please check your network connection or try again.',
        isUser: false,
        timestamp: DateTime.now(),
        responseType: AIResponseType.insufficientInformation,
        sources: const ['Network & Telemetry Diagnostics'],
        actions: const [
          AIActionItem(label: 'Explore Routes', actionType: 'EXPLORE_ROUTES'),
          AIActionItem(label: 'View Tickets', actionType: 'SHOW_TICKET'),
        ],
        dataOrigin: 'ERROR STATE',
      );
      state = [...state, errorMsg];
    } finally {
      _ref.read(aiLoadingProvider.notifier).state = false;
    }
  }

  void resetConversation() {
    state = [
      ChatMessage(
        id: 'msg-welcome-${DateTime.now().millisecondsSinceEpoch}',
        text: 'Conversation reset. How can I assist your transit journey today?',
        isUser: false,
        timestamp: DateTime.now(),
        responseType: AIResponseType.knowledge,
        sources: const ['BusSense AI'],
        actions: const [
          AIActionItem(label: 'Explore Routes', actionType: 'EXPLORE_ROUTES'),
        ],
        dataOrigin: 'VERIFIED KNOWLEDGE BASE',
      )
    ];
  }
}

/// AI Assistant Chat Messages Provider
final aiMessagesProvider = StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
  final repository = ref.watch(passengerRepositoryProvider);
  return AIChatNotifier(repository, ref);
});

// ============================================================
// H5 BATCH 4: PROFILE, FAVORITES, PREFERENCES & REPORTS
// ============================================================

/// User Profile Provider
final userProfileProvider = FutureProvider<UserModel>((ref) async {
  final repository = ref.watch(passengerRepositoryProvider);
  return repository.getUserProfile();
});

/// Saved Places Notifier
class SavedPlacesNotifier extends StateNotifier<AsyncValue<List<SavedPlaceModel>>> {
  final IPassengerRepository _repository;

  SavedPlacesNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchSavedPlaces();
  }

  Future<void> fetchSavedPlaces() async {
    try {
      final places = await _repository.getSavedPlaces();
      state = AsyncValue.data(places);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPlace(SavedPlaceModel place) async {
    final currentList = state.valueOrNull ?? [];
    try {
      final created = await _repository.addSavedPlace(place);
      state = AsyncValue.data([...currentList, created]);
    } catch (e) {
      // Local fallback in case network errors
      final fallback = place.copyWith(
        id: 'fav-local-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = AsyncValue.data([...currentList, fallback]);
    }
  }

  Future<void> deletePlace(String placeId) async {
    final currentList = state.valueOrNull ?? [];
    state = AsyncValue.data(currentList.where((p) => p.id != placeId).toList());
    try {
      await _repository.deleteSavedPlace(placeId);
    } catch (_) {
      // Keep optimistic delete
    }
  }
}

/// Saved Places Provider
final savedPlacesProvider = StateNotifierProvider<SavedPlacesNotifier, AsyncValue<List<SavedPlaceModel>>>((ref) {
  final repository = ref.watch(passengerRepositoryProvider);
  return SavedPlacesNotifier(repository);
});

/// User Preferences Notifier
class UserPreferencesNotifier extends StateNotifier<UserPreferencesModel> {
  final IPassengerRepository _repository;

  UserPreferencesNotifier(this._repository) : super(const UserPreferencesModel()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _repository.getUserPreferences();
      state = prefs;
    } catch (_) {
      // Maintain defaults
    }
  }

  Future<void> updatePreferences(UserPreferencesModel newPrefs) async {
    state = newPrefs;
    try {
      await _repository.updateUserPreferences(newPrefs);
    } catch (_) {
      // Local preference preserved
    }
  }

  void toggleMaster(bool val) {
    updatePreferences(state.copyWith(masterNotifications: val));
  }

  void setLanguage(String lang) {
    updatePreferences(state.copyWith(language: lang));
  }

  void setThemeMode(String mode) {
    updatePreferences(state.copyWith(themeMode: mode));
  }
}

/// User Preferences Provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferencesModel>((ref) {
  final repository = ref.watch(passengerRepositoryProvider);
  return UserPreferencesNotifier(repository);
});

/// Passenger Issue Reports Notifier
class PassengerReportsNotifier extends StateNotifier<List<PassengerReportModel>> {
  final IPassengerRepository _repository;

  PassengerReportsNotifier(this._repository) : super([]);

  Future<PassengerReportModel> submitReport(PassengerReportModel report) async {
    try {
      final created = await _repository.submitPassengerReport(report);
      state = [created, ...state];
      return created;
    } catch (e) {
      final fallback = PassengerReportModel(
        id: 'REP-KL-SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        category: report.category,
        title: report.title,
        description: report.description,
        busNumber: report.busNumber,
        routeNumber: report.routeNumber,
        status: 'REPORTED',
        createdAt: DateTime.now().toIso8601String(),
      );
      state = [fallback, ...state];
      return fallback;
    }
  }
}

/// Passenger Issue Reports Provider
final passengerReportsProvider = StateNotifierProvider<PassengerReportsNotifier, List<PassengerReportModel>>((ref) {
  final repository = ref.watch(passengerRepositoryProvider);
  return PassengerReportsNotifier(repository);
});

// ==============================================================================
// Phase H12: Realtime & Notifications Providers
// ==============================================================================

/// Centralized Realtime Client Provider
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// Realtime Connection State Provider
final realtimeStatusProvider = StreamProvider<RealtimeConnectionState>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client.stateStream;
});

/// Telemetry Freshness Label Provider
final telemetryFreshnessProvider = Provider<String>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client.freshnessLabel;
});

/// Telemetry Staleness Indicator Provider (>15s threshold)
final telemetryIsStaleProvider = Provider<bool>((ref) {
  final client = ref.watch(realtimeClientProvider);
  return client.isStale;
});

/// Notifier for In-App Commuter & Crew Notifications
class PassengerNotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationItemModel>>> {
  final IPassengerRepository _repository;

  PassengerNotificationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getNotifications(unreadOnly: unreadOnly);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String notificationId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n).toList(),
    );
    try {
      await _repository.markNotificationRead(notificationId);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await _repository.markAllNotificationsRead();
    } catch (_) {}
  }

  void addRealtimeNotification(NotificationItemModel notification) {
    final current = state.value ?? [];
    state = AsyncValue.data([notification, ...current]);
  }
}

/// Passenger Notifications Provider
final passengerNotificationsProvider = StateNotifierProvider<PassengerNotificationsNotifier, AsyncValue<List<NotificationItemModel>>>((ref) {
  final repo = ref.watch(passengerRepositoryProvider);
  return PassengerNotificationsNotifier(repo);
});

/// Unread Notifications Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncNotifs = ref.watch(passengerNotificationsProvider);
  return asyncNotifs.maybeWhen(
    data: (items) => items.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
