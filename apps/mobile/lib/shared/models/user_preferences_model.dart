/// User Preferences & Notification Settings
class UserPreferencesModel {
  final bool masterNotifications;
  final bool busArrival;
  final bool journeyUpdates;
  final bool crowdAlerts;
  final bool serviceAlerts;
  final bool ticketUpdates;
  final String language; // 'en' or 'ml'
  final String themeMode; // 'system', 'light', 'dark'

  const UserPreferencesModel({
    this.masterNotifications = true,
    this.busArrival = true,
    this.journeyUpdates = true,
    this.crowdAlerts = true,
    this.serviceAlerts = true,
    this.ticketUpdates = true,
    this.language = 'en',
    this.themeMode = 'system',
  });

  String get languageDisplay => language == 'ml' ? 'മലയാളം' : 'English (India)';

  String get themeModeDisplay {
    switch (themeMode) {
      case 'light':
        return 'Light Surface';
      case 'dark':
        return 'Dark Mode';
      case 'system':
      default:
        return 'System Default';
    }
  }

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      masterNotifications: json['master_notifications'] as bool? ?? true,
      busArrival: json['bus_arrival'] as bool? ?? true,
      journeyUpdates: json['journey_updates'] as bool? ?? true,
      crowdAlerts: json['crowd_alerts'] as bool? ?? true,
      serviceAlerts: json['service_alerts'] as bool? ?? true,
      ticketUpdates: json['ticket_updates'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
      themeMode: json['theme_mode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toJson() => {
        'master_notifications': masterNotifications,
        'bus_arrival': busArrival,
        'journey_updates': journeyUpdates,
        'crowd_alerts': crowdAlerts,
        'service_alerts': serviceAlerts,
        'ticket_updates': ticketUpdates,
        'language': language,
        'theme_mode': themeMode,
      };

  UserPreferencesModel copyWith({
    bool? masterNotifications,
    bool? busArrival,
    bool? journeyUpdates,
    bool? crowdAlerts,
    bool? serviceAlerts,
    bool? ticketUpdates,
    String? language,
    String? themeMode,
  }) {
    return UserPreferencesModel(
      masterNotifications: masterNotifications ?? this.masterNotifications,
      busArrival: busArrival ?? this.busArrival,
      journeyUpdates: journeyUpdates ?? this.journeyUpdates,
      crowdAlerts: crowdAlerts ?? this.crowdAlerts,
      serviceAlerts: serviceAlerts ?? this.serviceAlerts,
      ticketUpdates: ticketUpdates ?? this.ticketUpdates,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
