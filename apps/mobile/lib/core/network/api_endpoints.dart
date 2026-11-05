/// BusSense AI - Verified Backend Endpoints
class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Fleet & Corridors
  static const String buses = '/buses';
  static String bus(String busNumber) => '/buses/$busNumber';

  static const String routes = '/routes';
  static String route(String routeNumber) => '/routes/$routeNumber';

  static const String stops = '/stops';
  static const String stopsNearby = '/stops/nearby';

  // Trips & Corridors (H3)
  static const String trips = '/trips';
  static String trip(String tripId) => '/trips/$tripId';

  // Locations & GPS (H3)
  static const String locations = '/locations';
  static String location(String busIdentifier) => '/locations/$busIdentifier';

  // Crowd & Occupancy (H3)
  static const String crowd = '/crowd';
  static String busCrowd(String busIdentifier) => '/crowd/$busIdentifier';

  // Predictions & Demand (H3)
  static const String predictions = '/predictions';
  static String busPrediction(String busNumber) => '/predictions/$busNumber';
  static String occupancyForecast(String busNumber) => '/occupancy/forecast/$busNumber';

  // Ticketing (H2)
  static const String bookTicket = '/tickets/book';
  static const String myTickets = '/tickets/my';
  static const String validateTicket = '/tickets/validate';

  // Incidents & Alerts (H2/H3)
  static const String reportIncident = '/incidents/report';
  static const String alerts = '/alerts';
  static const String activeAlerts = '/alerts/active';

  // Payments (H3)
  static const String myPayments = '/payments/my';

  // Recommendations & AI
  static const String planJourney = '/recommendations/plan';
  static const String aiChat = '/ai/chat';

  // User Profile & Account (H5 Batch 4)
  static const String userProfile = '/user/profile';
  static const String userFavorites = '/user/favorites';
  static String userFavorite(String placeId) => '/user/favorites/$placeId';
  static const String userPreferences = '/user/preferences';
  static const String userReports = '/user/reports';
  static const String userExportData = '/user/export-data';
  static const String userDeactivate = '/user/deactivate';

  // Notifications & Realtime (H12)
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/mark-all-read';
  static const String realtimeEvents = '/realtime/events';
  static const String realtimeHealth = '/realtime/health';
  static const String pushStatus = '/notifications/push-status';
}
