/// Set model representing a set within a match
class VolleyballSet {
  final int setId;
  final int matchId;
  final int setNumber;
  final int homeTeamScore;
  final int awayTeamScore;
  final int? winnerTeamId;

  const VolleyballSet({
    required this.setId,
    required this.matchId,
    required this.setNumber,
    this.homeTeamScore = 0,
    this.awayTeamScore = 0,
    this.winnerTeamId,
  });

  /// Create a VolleyballSet from a JSON map
  factory VolleyballSet.fromJson(Map<String, dynamic> json) {
    return VolleyballSet(
      setId: json['set_id'] as int,
      matchId: json['match_id'] as int,
      setNumber: json['set_number'] as int,
      homeTeamScore: json['home_team_score'] as int? ?? 0,
      awayTeamScore: json['away_team_score'] as int? ?? 0,
      winnerTeamId: json['winner_team_id'] as int?,
    );
  }

  /// Convert VolleyballSet to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'set_id': setId,
      'match_id': matchId,
      'set_number': setNumber,
      'home_team_score': homeTeamScore,
      'away_team_score': awayTeamScore,
      'winner_team_id': winnerTeamId,
    };
  }

  /// Create a copy of VolleyballSet with some fields replaced
  VolleyballSet copyWith({
    int? setId,
    int? matchId,
    int? setNumber,
    int? homeTeamScore,
    int? awayTeamScore,
    int? winnerTeamId,
  }) {
    return VolleyballSet(
      setId: setId ?? this.setId,
      matchId: matchId ?? this.matchId,
      setNumber: setNumber ?? this.setNumber,
      homeTeamScore: homeTeamScore ?? this.homeTeamScore,
      awayTeamScore: awayTeamScore ?? this.awayTeamScore,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolleyballSet &&
          runtimeType == other.runtimeType &&
          setId == other.setId;

  @override
  int get hashCode => setId.hashCode;

  @override
  String toString() {
    return 'VolleyballSet{setId: $setId, matchId: $matchId, setNumber: $setNumber, homeTeamScore: $homeTeamScore, awayTeamScore: $awayTeamScore, winnerTeamId: $winnerTeamId}';
  }
}
