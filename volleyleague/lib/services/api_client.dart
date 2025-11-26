import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// HTTP client for all backend API calls with authentication support.
/// 
/// Automatically handles token refresh when access token is expired.
class ApiClient {
  ApiClient({
    this.baseUrl = 'http://localhost:8000',
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  final String baseUrl;
  final AuthService _authService;
  String? _authToken;
  bool _isRefreshing = false;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) {
          return null;
        }
        return json.decode(response.body);
      case 204:
        return null;
      case 400:
        throw ApiException('Bad request: ${response.body}');
      case 401:
        throw ApiException('Unauthorized - please login');
      case 403:
        throw ApiException('Forbidden - insufficient permissions');
      case 404:
        throw ApiException('Not found');
      case 422:
        throw ApiException('Validation error: ${response.body}');
      case 500:
        throw ApiException('Server error');
      default:
        throw ApiException('Error: ${response.statusCode}');
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String;
        final user = data['user'] as Map<String, dynamic>;

        await _authService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          userId: user['user_id'] as int,
          username: user['username'] as String,
          role: user['role'] as String,
        );

        _authToken = newAccessToken;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refreshes token if expired or expires within 5 minutes.
  Future<void> _ensureValidToken() async {
    // Load token from storage if not in memory
    _authToken ??= await _authService.getAccessToken();

    // Check if token needs refresh
    final needsRefresh = await _authService.isAccessTokenExpired();
    if (needsRefresh) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        throw ApiException('Session expired - please login again');
      }
    }
  }

  Future<dynamic> get(String endpoint) async {
    await _ensureValidToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );
      
      // If we get a 401, try refreshing once
      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    // Skip token check for auth endpoints
    if (!endpoint.startsWith('/api/login') && !endpoint.startsWith('/api/auth/register')) {
      await _ensureValidToken();
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      // If we get a 401 and it's not an auth endpoint, try refreshing
      if (response.statusCode == 401 && !endpoint.startsWith('/api/login') && !endpoint.startsWith('/api/auth/register')) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
            body: json.encode(body),
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    await _ensureValidToken();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
            body: json.encode(body),
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    await _ensureValidToken();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http.delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
