import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volleyleague/core/models/user.dart';
import 'package:volleyleague/services/repositories/user_repository.dart';
import 'package:volleyleague/services/auth_service.dart';
import 'package:volleyleague/core/logger.dart';
import 'package:volleyleague/core/exceptions.dart';
import 'auth_state.dart';

/// cubits are chosen over blocs due to 50 hour time constraint in my alevel NEA project
/// if development goes further the system will be transferred to bloc
class AuthCubit extends Cubit<AuthState> {
  final UserRepository _userRepository;
  final AuthService _authService;

  AuthCubit(this._userRepository, this._authService) : super(AuthInitial());

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      Log.d('[AuthCubit] Attempting login for username: $username');
      final response = await _userRepository.login(username, password);
      Log.d('[AuthCubit] Login API response received');
      
      final userJson = response['user'] as Map<String, dynamic>;
      Log.d('[AuthCubit] User JSON: $userJson');
      
      final user = User.fromJson(userJson);
      Log.d('[AuthCubit] User parsed: $user');
      
      final token = response['access_token'] as String;
      Log.d('[AuthCubit] Token received (length: ${token.length})');

      emit(AuthAuthenticated(user: user, token: token));
      Log.d('[AuthCubit] Emitted AuthAuthenticated state');
    } catch (e, stackTrace) {
      Log.e('[AuthCubit] Login error', e, stackTrace);
      final errorMessage = e is ApiException ? e.message : e.toString();
      emit(AuthError(errorMessage));
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required String role,
  }) async {
    emit(AuthLoading());
    try {
      await _userRepository.register(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
        role: role,
      );
      
      emit(AuthUnauthenticated());
    } catch (e) {
      final errorMessage = e is ApiException ? e.message : e.toString();
      emit(AuthError(errorMessage));
    }
  }

  Future<void> checkAuthStatus() async {
    // check this silently just for abstraction awau from user
    try {
      final isLoggedIn = await _userRepository.isLoggedIn();
      
      if (!isLoggedIn) {
        emit(AuthUnauthenticated());
        return;
      }

      final isExpired = await _authService.isAccessTokenExpired();
      if (isExpired) {
        await _authService.clearTokens();
        emit(AuthUnauthenticated());
        return;
      }

      final sessionRestored = await _userRepository.restoreSession();
      if (!sessionRestored) {
        emit(AuthUnauthenticated());
        return;
      }

      final user = await _userRepository.getCurrentUser();
      final token = await _authService.getAccessToken();
      
      if (user != null && token != null) {
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // On any error during startup check, just show login screen
      await _authService.clearTokens();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    // Don't emit loading during logout - just clear and navigate
    try {
      await _userRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even on error, clear tokens and show login screen
      await _authService.clearTokens();
      emit(AuthUnauthenticated());
    }
  }

  User? getCurrentUser() {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  String? getAuthToken() {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.token;
    }
    return null;
  }

  bool isAuthenticated() {
    return state is AuthAuthenticated;
  }
}
