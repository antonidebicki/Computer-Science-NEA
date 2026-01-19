import 'enums.dart';

// can represent any type of user just general class, helpful for me to code the other ones w the models
class User {
  final int userId;
  final String username;
  final String hashedPassword;
  final String email;
  final String? fullName;
  final UserRole role;
  final DateTime createdAt;

  const User({
    required this.userId,
    required this.username,
    required this.hashedPassword,
    required this.email,
    this.fullName,
    required this.role,
    required this.createdAt,
  });


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      hashedPassword: json['hashed_password'] as String? ?? '', 
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: UserRole.fromString(json['role'] as String),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'hashed_password': hashedPassword,
      'email': email,
      'full_name': fullName,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? hashedPassword,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'User{userId: $userId, username: $username, email: $email, fullName: $fullName, role: $role}';
  }
}
