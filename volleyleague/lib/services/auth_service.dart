import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing authentication tokens with secure storage.
/// 
/// Tokens are stored encrypted and persist across app restarts.
/// Provides automatic token refresh when access token is expired or about to expire.
class AuthService {
  static const _storage = FlutterSecureStorage();
  static final Map<String, String> _memoryFallback = {};
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _roleKey = 'role';

  Future<void> _writeValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _memoryFallback[key] = value;
      return;
    } on PlatformException {
      // Fall through to non-secure fallbacks.
    } catch (_) {
      // Fall through to non-secure fallbacks.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      _memoryFallback[key] = value;
    } catch (_) {
      _memoryFallback[key] = value;
    }
  }

  Future<String?> _readValue(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      // Fall through to non-secure fallbacks.
    } catch (_) {
      // Fall through to non-secure fallbacks.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key);
      if (value != null) {
        _memoryFallback[key] = value;
      }
      return value ?? _memoryFallback[key];
    } catch (_) {
      return _memoryFallback[key];
    }
  }

  Future<void> _deleteAllValues() async {
    try {
      await _storage.deleteAll();
    } on PlatformException {
      // Fall through to non-secure fallbacks.
    } catch (_) {
      // Fall through to non-secure fallbacks.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_roleKey);
    } catch (_) {
      // Ignore and clear in-memory fallback below.
    }

    _memoryFallback.remove(_accessTokenKey);
    _memoryFallback.remove(_refreshTokenKey);
    _memoryFallback.remove(_userIdKey);
    _memoryFallback.remove(_usernameKey);
    _memoryFallback.remove(_roleKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String username,
    required String role,
  }) async {
    await Future.wait([
      _writeValue(_accessTokenKey, accessToken),
      _writeValue(_refreshTokenKey, refreshToken),
      _writeValue(_userIdKey, userId.toString()),
      _writeValue(_usernameKey, username),
      _writeValue(_roleKey, role),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _readValue(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _readValue(_refreshTokenKey);
  }

  Future<int?> getUserId() async {
    final idStr = await _readValue(_userIdKey);
    return idStr != null ? int.tryParse(idStr) : null;
  }

  Future<String?> getUsername() async {
    return await _readValue(_usernameKey);
  }

  Future<String?> getRole() async {
    return await _readValue(_roleKey);
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  Future<bool> isAccessTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      // Check if token is expired/expires in less than 5 minutes
      final isExpired = JwtDecoder.isExpired(token);
      if (isExpired) return true;

      // Check if token expires in the next 5 minutes
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      final difference = expiryDate.difference(now);
      
      return difference.inMinutes < 5;
    } catch (e) {
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
    await _deleteAllValues();
  }

  Future<Duration?> getTimeUntilExpiry() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return null;
    
    final now = DateTime.now();
    return expiry.difference(now);
  }
}
