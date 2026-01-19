class SeasonTeam {
  final int seasonId;
  final int teamId;
  final DateTime joinDate;

  const SeasonTeam({
    required this.seasonId,
    required this.teamId,
    required this.joinDate,
  });

  factory SeasonTeam.fromJson(Map<String, dynamic> json) {
    return SeasonTeam(
      seasonId: json['season_id'] as int,
      teamId: json['team_id'] as int,
      joinDate: DateTime.parse(json['join_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season_id': seasonId,
      'team_id': teamId,
      'join_date': joinDate.toIso8601String().split('T')[0], // Date only
    };
  }

  SeasonTeam copyWith({
    int? seasonId,
    int? teamId,
    DateTime? joinDate,
  }) {
    return SeasonTeam(
      seasonId: seasonId ?? this.seasonId,
      teamId: teamId ?? this.teamId,
      joinDate: joinDate ?? this.joinDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonTeam &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId &&
          teamId == other.teamId;

  @override
  int get hashCode => Object.hash(seasonId, teamId);

  @override
  String toString() {
    return 'SeasonTeam{seasonId: $seasonId, teamId: $teamId, joinDate: $joinDate}';
  }
}
