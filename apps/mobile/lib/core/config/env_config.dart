/// BusSense AI - Mobile Environment Configuration
/// Configured for Production Cloud Architecture with zero localhost fallbacks in release.
class EnvConfig {
  // Supabase Production Configuration (Greater Kochi Transit Network)
  static const String defaultSupabaseUrl = 'https://lqegmqgkymstycpzplld.supabase.co';
  static const String defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxxZWdtcWdreW1zdHljcHpwbGxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0MTg4MTksImV4cCI6MjEwNTk5NDgxOX0.7GxTajcD4CyhlyTca39zziut7DntTQuBsYebZz2hVu0';
  static const String defaultAndroidUrl = 'http://10.0.2.2:8000/api';
  static const String defaultIosUrl = 'http://localhost:8000/api';
  static const String defaultEdgeFunctionApiUrl = 'https://lqegmqgkymstycpzplld.supabase.co/functions/v1/api';
  static const String defaultPostgrestUrl = 'https://lqegmqgkymstycpzplld.supabase.co/rest/v1';

  static String supabaseUrl = const bool.hasEnvironment('SUPABASE_URL')
      ? const String.fromEnvironment('SUPABASE_URL')
      : defaultSupabaseUrl;

  static String supabaseAnonKey = const bool.hasEnvironment('SUPABASE_ANON_KEY')
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : defaultSupabaseAnonKey;

  /// Default API URL defaults to production Supabase cloud gateway
  static String apiBaseUrl = const bool.hasEnvironment('API_BASE_URL')
      ? const String.fromEnvironment('API_BASE_URL')
      : defaultEdgeFunctionApiUrl;

  static const String defaultAuthorityPortalUrl = 'http://localhost:3000/authority/command';

  static String authorityPortalUrl = const bool.hasEnvironment('AUTHORITY_PORTAL_URL')
      ? const String.fromEnvironment('AUTHORITY_PORTAL_URL')
      : defaultAuthorityPortalUrl;

  static const Duration requestTimeout = Duration(seconds: 12);
  static const String defaultCity = 'Kochi';

  /// Configure API base URL dynamically for different deployment environments
  static void setBaseUrl(String url) {
    apiBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Configure Authority Web Portal URL dynamically
  static void setAuthorityPortalUrl(String url) {
    authorityPortalUrl = url;
  }

  /// Switch client to production Supabase-native Edge Function gateway
  static void useProductionSupabase() {
    apiBaseUrl = defaultEdgeFunctionApiUrl;
  }

  /// Switch client to direct Supabase PostgREST layer
  static void usePostgrestDirect() {
    apiBaseUrl = defaultPostgrestUrl;
  }
}
