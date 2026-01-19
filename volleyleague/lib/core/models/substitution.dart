class Substitution {
  final int substitutionId;
  final int setId;
  final int teamId;
  final int playerInUserId;
  final int playerOutUserId;
  final String? scoreAtSubstitution;
  final DateTime timestamp;

  const Substitution({
    required this.substitutionId,
    required this.setId,
    required this.teamId,
    required this.playerInUserId,
    required this.playerOutUserId,
    this.scoreAtSubstitution,
    required this.timestamp,
  });


  factory Substitution.fromJson(Map<String, dynamic> json) {
    return Substitution(
      substitutionId: json['substitution_id'] as int,
      setId: json['set_id'] as int,
      teamId: json['team_id'] as int,
      playerInUserId: json['player_in_user_id'] as int,
      playerOutUserId: json['player_out_user_id'] as int,
      scoreAtSubstitution: json['score_at_substitution'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'substitution_id': substitutionId,
      'set_id': setId,
      'team_id': teamId,
      'player_in_user_id': playerInUserId,
      'player_out_user_id': playerOutUserId,
      'score_at_substitution': scoreAtSubstitution,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Substitution copyWith({
    int? substitutionId,
    int? setId,
    int? teamId,
    int? playerInUserId,
    int? playerOutUserId,
    String? scoreAtSubstitution,
    DateTime? timestamp,
  }) {
    return Substitution(
      substitutionId: substitutionId ?? this.substitutionId,
      setId: setId ?? this.setId,
      teamId: teamId ?? this.teamId,
      playerInUserId: playerInUserId ?? this.playerInUserId,
      playerOutUserId: playerOutUserId ?? this.playerOutUserId,
      scoreAtSubstitution: scoreAtSubstitution ?? this.scoreAtSubstitution,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Substitution &&
          runtimeType == other.runtimeType &&
          substitutionId == other.substitutionId;

  @override
  int get hashCode => substitutionId.hashCode;

  @override
  String toString() {
    return 'Substitution{substitutionId: $substitutionId, setId: $setId, teamId: $teamId, playerInUserId: $playerInUserId, playerOutUserId: $playerOutUserId, scoreAtSubstitution: $scoreAtSubstitution, timestamp: $timestamp}';
  }
}
