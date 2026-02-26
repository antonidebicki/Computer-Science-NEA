class AppConstants {
  static const String appName = 'VolleyLeague';
  
  // API Base URL - can be overridden via --dart-define=API_BASE_URL=... when running flutter
  // Default URLs for different scenarios:
  static const String _defaultApiBaseUrl = 'http://localhost:8000';
  
  static String get apiBaseUrl {
    // Try to get from dart:io environment variable (set via --dart-define)
    const apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    return _defaultApiBaseUrl;
  }
  
  // Alternative URLs for different platforms (if needed):
  // Android emulator: http://10.0.2.2:8000
  // Physical device on network: http://192.168.1.x:8000
  // iOS simulator: http://localhost:8000
}
