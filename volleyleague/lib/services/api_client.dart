import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../core/exceptions.dart';
import '../core/constants.dart';

/// HTTP client for all backend API calls with authentication support.
/// 
/// Automatically handles token refresh when access token is expired.
class ApiClient {
  ApiClient({
    String? baseUrl,
    AuthService? authService,
  }) : baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
       _authService = authService ?? AuthService();

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
        final errorData = _parseErrorMessage(response.body);
        throw ApiException(errorData);
      case 401:
        final errorData = _parseErrorMessage(response.body);
        throw ApiException(errorData);
      case 403:
        final errorData = _parseErrorMessage(response.body);
        throw ApiException(errorData);
      case 404:
        throw ApiException('Not found');
      case 422:
        final errorData = _parseErrorMessage(response.body);
        throw ApiException(errorData);
      case 500:
        throw ApiException('Server error - please try again later');
      default:
        throw ApiException('Error: ${response.statusCode}');
    }
  }

  String _parseErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data is Map && data.containsKey('detail')) {
        return data['detail'] as String;
      }
      return responseBody;
    } catch (e) {
      return responseBody;
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

  /// Core method that handles all HTTP requests with automatic retry on 401.
  /// Eliminates code duplication across GET, POST, PUT, DELETE methods.
  Future<dynamic> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool skipTokenCheck = false,
  }) async {
    // Skip token validation for auth endpoints
    if (!skipTokenCheck) {
      await _ensureValidToken();
    }

    try {
      // Make initial request
      http.Response response = await _executeRequest(method, endpoint, body);

      // Handle 401 by refreshing token and retrying (but not for auth endpoints)
      if (response.statusCode == 401 && !skipTokenCheck) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          response = await _executeRequest(method, endpoint, body);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Executes the actual HTTP request based on method type.
  Future<http.Response> _executeRequest(
    String method,
    String endpoint,
    Map<String, dynamic>? body,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = _getHeaders();

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: json.encode(body));
      case 'PUT':
        return await http.put(uri, headers: headers, body: json.encode(body));
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }
  }

  Future<dynamic> get(String endpoint) async {
    return _makeRequest('GET', endpoint);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    // Skip token check for auth endpoints
    final skipToken = endpoint.startsWith('/api/login') || 
                      endpoint.startsWith('/api/auth/register');
    return _makeRequest('POST', endpoint, body: body, skipTokenCheck: skipToken);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    return _makeRequest('PUT', endpoint, body: body);
  }

  Future<dynamic> delete(String endpoint) async {
    return _makeRequest('DELETE', endpoint);
  }
}
