class TeamMember {
  final int teamId;
  final int userId;
  final String roleInTeam;
  final int? playerNumber;
  final bool isCaptain;
  final bool isLibero;
  final String username;
  final String email;
  final String? fullName;
  final String userRole;

  const TeamMember({
    required this.teamId,
    required this.userId,
    this.roleInTeam = 'Player',
    this.playerNumber,
    this.isCaptain = false,
    this.isLibero = false,
    required this.username,
    required this.email,
    this.fullName,
    required this.userRole,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      teamId: json['team_id'] as int,
      userId: json['user_id'] as int,
      roleInTeam: json['role_in_team'] as String? ?? 'Player',
      playerNumber: json['player_number'] as int?,
      isCaptain: json['is_captain'] as bool? ?? false,
      isLibero: json['is_libero'] as bool? ?? false,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      userRole: json['user_role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'user_id': userId,
      'role_in_team': roleInTeam,
      'player_number': playerNumber,
      'is_captain': isCaptain,
      'is_libero': isLibero,
      'username': username,
      'email': email,
      'full_name': fullName,
      'user_role': userRole,
    };
  }

  TeamMember copyWith({
    int? teamId,
    int? userId,
    String? roleInTeam,
    int? playerNumber,
    bool? isCaptain,
    bool? isLibero,
    String? username,
    String? email,
    String? fullName,
    String? userRole,
  }) {
    return TeamMember(
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      roleInTeam: roleInTeam ?? this.roleInTeam,
      playerNumber: playerNumber ?? this.playerNumber,
      isCaptain: isCaptain ?? this.isCaptain,
      isLibero: isLibero ?? this.isLibero,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      userRole: userRole ?? this.userRole,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(teamId, userId);

  @override
  String toString() {
    return 'TeamMember{teamId: $teamId, userId: $userId, roleInTeam: $roleInTeam, playerNumber: $playerNumber, isCaptain: $isCaptain, isLibero: $isLibero, username: $username, fullName: $fullName}';
  }
}
