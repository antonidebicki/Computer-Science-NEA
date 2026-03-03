import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'VolleyLeague';

  // API Base URL - can be overridden via --dart-define=API_BASE_URL=... when running flutter
  // Defaults by build mode:
  // - debug/profile: localhost for local backend development
  // - release: Render production API
  static const String _debugApiBaseUrl = 'http://localhost:8000';
  static const String _releaseApiBaseUrl =
      'https://volleyleague-api.onrender.com';

  static String get apiBaseUrl {
    // Try to get from dart:io environment variable (set via --dart-define)
    const apiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    return kReleaseMode ? _releaseApiBaseUrl : _debugApiBaseUrl;
  }

  // Alternative URLs for different platforms (if needed):
  // Android emulator: http://10.0.2.2:8000
  // Physical device on network: http://192.168.1.x:8000
  // iOS simulator: http://localhost:8000
}
