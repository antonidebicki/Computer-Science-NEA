/// TeamMember model representing the relationship between a team and its members
class TeamMember {
  final int teamId;
  final int userId;
  final String roleInTeam;
  final int? playerNumber;
  final bool isCaptain;
  final bool isLibero;

  const TeamMember({
    required this.teamId,
    required this.userId,
    this.roleInTeam = 'Player',
    this.playerNumber,
    this.isCaptain = false,
    this.isLibero = false,
  });

  /// Create a TeamMember from a JSON map
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      teamId: json['team_id'] as int,
      userId: json['user_id'] as int,
      roleInTeam: json['role_in_team'] as String? ?? 'Player',
      playerNumber: json['player_number'] as int?,
      isCaptain: json['is_captain'] as bool? ?? false,
      isLibero: json['is_libero'] as bool? ?? false,
    );
  }

  /// Convert TeamMember to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'user_id': userId,
      'role_in_team': roleInTeam,
      'player_number': playerNumber,
      'is_captain': isCaptain,
      'is_libero': isLibero,
    };
  }

  /// Create a copy of TeamMember with some fields replaced
  TeamMember copyWith({
    int? teamId,
    int? userId,
    String? roleInTeam,
    int? playerNumber,
    bool? isCaptain,
    bool? isLibero,
  }) {
    return TeamMember(
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      roleInTeam: roleInTeam ?? this.roleInTeam,
      playerNumber: playerNumber ?? this.playerNumber,
      isCaptain: isCaptain ?? this.isCaptain,
      isLibero: isLibero ?? this.isLibero,
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
    return 'TeamMember{teamId: $teamId, userId: $userId, roleInTeam: $roleInTeam, playerNumber: $playerNumber, isCaptain: $isCaptain, isLibero: $isLibero}';
  }
}
