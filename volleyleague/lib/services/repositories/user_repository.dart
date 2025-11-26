import '../../core/models/user.dart';
import '../../core/models/enums.dart';
import '../api_client.dart';
import '../auth_service.dart';

/// Repository for user-related operations including authentication.
class UserRepository {
  final ApiClient _apiClient;
  final AuthService _authService;

  UserRepository(this._apiClient, [AuthService? authService])
      : _authService = authService ?? AuthService();

  /// Automatically stores tokens in secure storage and sets auth token in ApiClient.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiClient.post('/api/login', {
      'username': username,
      'password': password,
    });

    // Extract tokens and user info
    final accessToken = response['access_token'] as String;
    final refreshToken = response['refresh_token'] as String;
    final userInfo = response['user'] as Map<String, dynamic>;

    // Store tokens securely
    await _authService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userInfo['user_id'] as int,
      username: userInfo['username'] as String,
      role: userInfo['role'] as String,
    );

    // Set token in API client for subsequent requests
    _apiClient.setAuthToken(accessToken);

    return response;
  }

  /// Does not automatically log in - call login() after successful registration.
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required String role,
  }) async {
    await _apiClient.post('/api/auth/register', {
      'username': username,
      'password': password,
      'email': email,
      'full_name': fullName,
      'role': role,
    });
  }

  Future<User?> getCurrentUser() async {
    final userId = await _authService.getUserId();
    final username = await _authService.getUsername();
    final role = await _authService.getRole();
    
    if (userId == null || username == null || role == null) return null;

    return User(
      userId: userId,
      username: username,
      hashedPassword: '',
      email: '',
      role: UserRole.fromString(role),
      createdAt: DateTime.now(),
    );
  }

  /// Clears all stored tokens and removes auth token from ApiClient.
  Future<void> logout() async {
    await _authService.clearTokens();
    _apiClient.clearAuthToken();
  }

  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Call on app startup to restore session from stored tokens.
  Future<bool> restoreSession() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) return false;

    final accessToken = await _authService.getAccessToken();
    if (accessToken != null) {
      _apiClient.setAuthToken(accessToken);
      return true;
    }

    return false;
  }
}
