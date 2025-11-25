# Token Storage & Auto-Refresh Implementation

## Overview

This implementation provides secure token storage and automatic token refresh for the VolleyLeague Flutter app.

## Components

### 1. Backend (Already Implemented)
- **Access tokens**: Expire after 24 hours
- **Refresh tokens**: Expire after 30 days
- **`/auth/login`**: Returns both access and refresh tokens
- **`/auth/refresh`**: Exchanges refresh token for new access + refresh tokens

### 2. AuthService (`lib/services/auth_service.dart`)

**Purpose**: Manages secure token storage and expiry checking.

**Storage**: Uses `flutter_secure_storage` which:
- Encrypts data on device (uses Keychain on iOS, KeyStore on Android)
- Persists across app restarts
- Automatically cleared on app uninstall

**Key Methods**:
```dart
saveTokens()           // Store tokens after login/refresh
getAccessToken()       // Retrieve current access token
getRefreshToken()      // Retrieve current refresh token
isAccessTokenExpired() // Check if token needs refresh (expires in <5 min)
clearTokens()          // Logout - clear all stored data
```

**Token Expiry Logic**:
- Uses `jwt_decoder` to parse JWT tokens
- Checks if token expires in next 5 minutes (proactive refresh)
- Returns `true` if token is invalid/corrupted

### 3. ApiClient (`lib/services/api_client.dart`)

**Purpose**: HTTP client with automatic token refresh.

**Auto-Refresh Flow**:
```
1. Before each API call → Check if token expires in <5 minutes
2. If yes → Call /auth/refresh endpoint
3. If refresh succeeds → Update stored tokens and retry request
4. If refresh fails → Throw "Session expired" error
5. If API returns 401 → Attempt refresh once and retry
```

**Key Methods**:
```dart
_ensureValidToken()     // Check and refresh if needed (called before requests)
_refreshAccessToken()   // Call /auth/refresh and update storage
get/post/put/delete()   // HTTP methods with auto-refresh
```

**Features**:
- Skips token validation for `/auth/*` endpoints (login, register)
- Prevents concurrent refresh attempts with `_isRefreshing` flag
- Automatically retries failed request after successful refresh
- Loads token from storage on first request if not in memory

## Usage Flow

### Login
```dart
// 1. User logs in
final response = await apiClient.post('/auth/login', {
  'username': 'user',
  'password': 'pass',
});

// 2. Save tokens
await authService.saveTokens(
  accessToken: response['access_token'],
  refreshToken: response['refresh_token'],
  userId: response['user']['user_id'],
  username: response['user']['username'],
  role: response['user']['role'],
);

// 3. Set token in ApiClient
apiClient.setAuthToken(response['access_token']);
```

### Making Authenticated Requests
```dart
// Just make the request - token refresh is automatic!
final data = await apiClient.get('/seasons');
// ApiClient will:
// - Check if token expires soon
// - Refresh if needed
// - Retry if 401 received
```

### Logout
```dart
await authService.clearTokens();
apiClient.clearAuthToken();
```

### Check Login Status
```dart
final isLoggedIn = await authService.isLoggedIn();
if (isLoggedIn) {
  // Load token into ApiClient
  final token = await authService.getAccessToken();
  apiClient.setAuthToken(token);
}
```

## Token Refresh Timing

**Proactive Refresh** (before expiry):
- Triggers when token expires in less than 5 minutes
- Happens automatically before API calls
- Prevents 401 errors from expired tokens

**Reactive Refresh** (after 401):
- If backend returns 401 Unauthorized
- Attempts one refresh and retries request
- Catches edge cases (clock skew, manual token invalidation)

## Security Considerations

✅ **Tokens encrypted at rest** (flutter_secure_storage)
✅ **Tokens cleared on logout**
✅ **No tokens in code or logs**
✅ **HTTPS only in production** (configure baseUrl)
✅ **Refresh token rotation** (backend issues new refresh token each time)

## Testing Checklist

- [ ] Login stores tokens correctly
- [ ] App restart preserves login session
- [ ] Token auto-refreshes before 24h expiry
- [ ] 401 errors trigger refresh attempt
- [ ] Logout clears all tokens
- [ ] Failed refresh shows "session expired" error
- [ ] Concurrent requests don't trigger multiple refreshes

## Dependencies

```yaml
dependencies:
  http: ^1.2.39                      # HTTP client
  flutter_secure_storage: ^9.2.2    # Encrypted storage
  jwt_decoder: ^2.0.1                # JWT parsing
```

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Implement login UI that calls AuthService
3. Create app initialization that checks isLoggedIn()
4. Add logout button that calls clearTokens()
5. Test token refresh by waiting 23+ hours (or modify backend expiry for testing)
