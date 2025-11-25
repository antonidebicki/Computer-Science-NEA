import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Service for managing authentication tokens with secure storage.
/// 
/// Tokens are stored encrypted and persist across app restarts.
/// Provides automatic token refresh when access token is expired or about to expire.
class AuthService {
  static const _storage = FlutterSecureStorage();
  
  // Storage keys
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _roleKey = 'role';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String username,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId.toString()),
      _storage.write(key: _usernameKey, value: username),
      _storage.write(key: _roleKey, value: role),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<int?> getUserId() async {
    final idStr = await _storage.read(key: _userIdKey);
    return idStr != null ? int.tryParse(idStr) : null;
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Returns true if token expires within 5 minutes.
  Future<bool> isAccessTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      // Check if token is expired or expires in less than 5 minutes
      final isExpired = JwtDecoder.isExpired(token);
      if (isExpired) return true;

      // Check if token expires in the next 5 minutes
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      final difference = expiryDate.difference(now);
      
      return difference.inMinutes < 5;
    } catch (e) {
      // If we can't decode the token, consider it expired
      return true;
    }
  }

  Future<DateTime?> getAccessTokenExpiry() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<Duration?> getTimeUntilExpiry() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return null;
    
    final now = DateTime.now();
    return expiry.difference(now);
  }
}
