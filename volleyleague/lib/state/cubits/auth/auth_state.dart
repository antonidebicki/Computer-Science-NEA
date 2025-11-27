import 'package:volleyleague/core/models/user.dart';

// base class
abstract class AuthState {}


class AuthInitial extends AuthState {}

/// show loading indicator
class AuthLoading extends AuthState {}

///successful auth
class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  AuthAuthenticated({
    required this.user,
    required this.token,
  });
}

///no auth
class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
