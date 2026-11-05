import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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

/// Abstract contract for Passenger operations (enables clean testing & mocking)
abstract class IPassengerRepository {
  Future<List<BusModel>> getLiveBuses();
  Future<BusModel> getBusDetails(String busNumber);
  Future<List<LocationModel>> getLiveLocations();
  Future<LocationModel?> getBusLocation(String busIdentifier);
  Future<List<CrowdModel>> getFleetCrowd();
  Future<CrowdModel?> getBusCrowd(String busIdentifier);
  Future<PredictionModel> getBusPrediction(String busNumber);
  Future<JourneyPlanModel> getJourneyPlan({
    required String origin,
    required String destination,
  });
  Future<List<AlertModel>> getActiveAlerts();
  Future<List<TripModel>> getActiveTrips();
  Future<TicketModel> bookTicket({
    required String busNumber,
    required String routeNumber,
    required String originStop,
    required String destinationStop,
    required String passengerName,
    required double fareAmount,
    String? tripId,
    String paymentMethod = 'SIMULATED_UPI',
  });
  Future<List<TicketModel>> getMyTickets();
  Future<AIQueryResponse> askAiAssistant({
    required String question,
    String? activeBusContext,
    String? destinationContext,
    String? ticketId,
  });

  // User Profile, Favorites, Preferences & Reporting (H5 Batch 4)
  Future<UserModel> getUserProfile();
  Future<UserModel> updateUserProfile({required String fullName, String? preferredLanguage});
  Future<List<SavedPlaceModel>> getSavedPlaces();
  Future<SavedPlaceModel> addSavedPlace(SavedPlaceModel place);
  Future<void> deleteSavedPlace(String placeId);
  Future<UserPreferencesModel> getUserPreferences();
  Future<UserPreferencesModel> updateUserPreferences(UserPreferencesModel preferences);
  Future<PassengerReportModel> submitPassengerReport(PassengerReportModel report);
  Future<Map<String, dynamic>> exportUserData();
  Future<void> deactivateAccount();

  // In-App Notifications (H12)
  Future<List<NotificationItemModel>> getNotifications({bool unreadOnly = false, int limit = 20, int offset = 0}) async => [];
  Future<int> getUnreadNotificationCount() async => 0;
  Future<bool> markNotificationRead(String notificationId) async => true;
  Future<int> markAllNotificationsRead() async => 0;
}

/// Production implementation of [IPassengerRepository] consuming verified FastAPI endpoints
class PassengerRepository implements IPassengerRepository {
  final ApiClient _apiClient;

  PassengerRepository(this._apiClient);

  @override
  Future<List<BusModel>> getLiveBuses() async {
    final response = await _apiClient.get(ApiEndpoints.buses);
    if (response is List) {
      return response.map((e) => BusModel.fromJson(e as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => BusModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<BusModel> getBusDetails(String busNumber) async {
    final response = await _apiClient.get(ApiEndpoints.bus(busNumber));
    if (response is Map<String, dynamic>) {
      return BusModel.fromJson(response);
    }
    throw Exception('Failed to load bus details for $busNumber');
  }

  @override
  Future<List<LocationModel>> getLiveLocations() async {
    final response = await _apiClient.get(ApiEndpoints.locations);
    if (response is List) {
      return response.map((e) => LocationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<LocationModel?> getBusLocation(String busIdentifier) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.location(busIdentifier));
      if (response is Map<String, dynamic>) {
        return LocationModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<CrowdModel>> getFleetCrowd() async {
    final response = await _apiClient.get(ApiEndpoints.crowd);
    if (response is List) {
      return response.map((e) => CrowdModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<CrowdModel?> getBusCrowd(String busIdentifier) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.busCrowd(busIdentifier));
      if (response is Map<String, dynamic>) {
        return CrowdModel.fromJson(response);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<PredictionModel> getBusPrediction(String busNumber) async {
    final response = await _apiClient.get(ApiEndpoints.busPrediction(busNumber));
    if (response is List) {
      return PredictionModel.fromForecastList(busNumber, response);
    } else if (response is Map<String, dynamic>) {
      return PredictionModel.fromJson(response);
    }
    throw Exception('Failed to load prediction for bus $busNumber');
  }

  @override
  Future<JourneyPlanModel> getJourneyPlan({
    required String origin,
    required String destination,
  }) async {
    final queryParams = {
      'origin': origin,
      'destination': destination,
    };
    final response = await _apiClient.get(
      ApiEndpoints.planJourney,
      queryParams: queryParams,
    );
    if (response is Map<String, dynamic>) {
      return JourneyPlanModel.fromJson(response);
    }
    throw Exception('Failed to generate journey plan between $origin and $destination');
  }

  @override
  Future<List<AlertModel>> getActiveAlerts() async {
    final response = await _apiClient.get(ApiEndpoints.activeAlerts);
    if (response is List) {
      return response.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<List<TripModel>> getActiveTrips() async {
    final response = await _apiClient.get(ApiEndpoints.trips);
    if (response is List) {
      return response.map((e) => TripModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

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
    final body = <String, dynamic>{
      'bus_number': busNumber,
      'route_number': routeNumber,
      'origin_stop': originStop,
      'destination_stop': destinationStop,
      'passenger_name': passengerName,
      'fare_amount': fareAmount,
      'payment_method': paymentMethod,
    };
    if (tripId != null) {
      body['trip_id'] = tripId;
    }
    final response = await _apiClient.post(ApiEndpoints.bookTicket, body: body);
    if (response is Map<String, dynamic>) {
      return TicketModel.fromJson(response);
    }
    throw Exception('Failed to issue digital boarding pass');
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    final response = await _apiClient.get(ApiEndpoints.myTickets);
    if (response is List) {
      return response.map((e) => TicketModel.fromJson(e as Map<String, dynamic>)).toList();
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
    final Map<String, dynamic> body = {
      'question': question,
      'message': question,
    };
    if (activeBusContext != null) {
      body['active_bus_context'] = activeBusContext;
    }
    if (destinationContext != null) {
      body['destination_context'] = destinationContext;
    }
    if (activeBusContext != null || destinationContext != null || ticketId != null) {
      final Map<String, dynamic> ctx = {};
      if (activeBusContext != null) ctx['bus_number'] = activeBusContext;
      if (destinationContext != null) ctx['destination'] = destinationContext;
      if (ticketId != null) ctx['ticket_id'] = ticketId;
      body['context'] = ctx;
    }
    final response = await _apiClient.post(ApiEndpoints.aiChat, body: body);
    if (response is Map<String, dynamic>) {
      return AIQueryResponse.fromJson(response);
    }
    throw Exception('Failed to receive response from BusSense AI');
  }

  @override
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.get(ApiEndpoints.userProfile);
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Failed to load user profile');
  }

  @override
  Future<UserModel> updateUserProfile({required String fullName, String? preferredLanguage}) async {
    final Map<String, dynamic> body = {
      'full_name': fullName,
    };
    if (preferredLanguage != null) {
      body['preferred_language'] = preferredLanguage;
    }
    final response = await _apiClient.patch(ApiEndpoints.userProfile, body: body);
    if (response is Map<String, dynamic>) {
      return UserModel.fromJson(response);
    }
    throw Exception('Failed to update user profile');
  }

  @override
  Future<List<SavedPlaceModel>> getSavedPlaces() async {
    final response = await _apiClient.get(ApiEndpoints.userFavorites);
    if (response is List) {
      return response.map((e) => SavedPlaceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<SavedPlaceModel> addSavedPlace(SavedPlaceModel place) async {
    final response = await _apiClient.post(
      ApiEndpoints.userFavorites,
      body: place.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return SavedPlaceModel.fromJson(response);
    }
    throw Exception('Failed to save destination');
  }

  @override
  Future<void> deleteSavedPlace(String placeId) async {
    await _apiClient.delete(ApiEndpoints.userFavorite(placeId));
  }

  @override
  Future<UserPreferencesModel> getUserPreferences() async {
    final response = await _apiClient.get(ApiEndpoints.userPreferences);
    if (response is Map<String, dynamic>) {
      return UserPreferencesModel.fromJson(response);
    }
    return const UserPreferencesModel();
  }

  @override
  Future<UserPreferencesModel> updateUserPreferences(UserPreferencesModel preferences) async {
    final response = await _apiClient.put(
      ApiEndpoints.userPreferences,
      body: preferences.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return UserPreferencesModel.fromJson(response);
    }
    return preferences;
  }

  @override
  Future<PassengerReportModel> submitPassengerReport(PassengerReportModel report) async {
    final response = await _apiClient.post(
      ApiEndpoints.userReports,
      body: report.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return PassengerReportModel.fromJson(response);
    }
    throw Exception('Failed to submit passenger report');
  }

  @override
  Future<Map<String, dynamic>> exportUserData() async {
    final response = await _apiClient.get(ApiEndpoints.userExportData);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'status': 'EXPORT_FAILED'};
  }

  @override
  Future<void> deactivateAccount() async {
    await _apiClient.post(
      ApiEndpoints.userDeactivate,
      body: {'confirm': true},
    );
  }

  @override
  Future<List<NotificationItemModel>> getNotifications({
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParams: {
        'unread_only': unreadOnly,
        'limit': limit,
        'offset': offset,
      },
    );
    if (response is List) {
      return response
          .map((item) => NotificationItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    final response = await _apiClient.get(ApiEndpoints.unreadNotificationsCount);
    if (response is Map<String, dynamic>) {
      return (response['unread_count'] as int?) ?? 0;
    }
    return 0;
  }

  @override
  Future<bool> markNotificationRead(String notificationId) async {
    final response = await _apiClient.patch(ApiEndpoints.markNotificationRead(notificationId));
    return response == true;
  }

  @override
  Future<int> markAllNotificationsRead() async {
    final response = await _apiClient.post(ApiEndpoints.markAllNotificationsRead);
    if (response is Map<String, dynamic>) {
      return (response['marked_count'] as int?) ?? 0;
    }
    return 0;
  }
}
