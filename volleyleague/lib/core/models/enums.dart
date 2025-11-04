/// Enum types for the VolleyLeague application
/// These correspond to the PostgreSQL ENUM types in the database schema
library;

/// User role types
enum UserRole {
  admin('ADMIN'),
  coach('COACH'),
  player('PLAYER'),
  referee('REFEREE');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value.toUpperCase(),
      orElse: () => UserRole.player,
    );
  }

  @override
  String toString() => value;
}

/// Game/Match state types
enum GameState {
  unscheduled('UNSCHEDULED'),
  scheduled('SCHEDULED'),
  finished('FINISHED'),
  processed('PROCESSED');

  final String value;
  const GameState(this.value);

  static GameState fromString(String value) {
    return GameState.values.firstWhere(
      (state) => state.value == value.toUpperCase(),
      orElse: () => GameState.scheduled,
    );
  }

  @override
  String toString() => value;
}

/// Payment status types
enum PaymentStatus {
  unpaid('UNPAID'),
  paid('PAID'),
  overdue('OVERDUE');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => PaymentStatus.unpaid,
    );
  }

  @override
  String toString() => value;
}
