class LeagueStanding {
  final int standingId;
  final int seasonId;
  final int teamId;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int setsWon;
  final int setsLost;
  final int pointsWon;
  final int pointsLost;
  final int leaguePoints;

  const LeagueStanding({
    required this.standingId,
    required this.seasonId,
    required this.teamId,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.setsWon = 0,
    this.setsLost = 0,
    this.pointsWon = 0,
    this.pointsLost = 0,
    this.leaguePoints = 0,
  });

  int get setDifference => setsWon - setsLost;
  int get pointDifference => pointsWon - pointsLost;

  double get winPercentage =>
      matchesPlayed > 0 ? (wins / matchesPlayed) * 100 : 0.0;

  factory LeagueStanding.fromJson(Map<String, dynamic> json) {
    return LeagueStanding(
      standingId: json['standing_id'] as int,
      seasonId: json['season_id'] as int,
      teamId: json['team_id'] as int,
      matchesPlayed: json['matches_played'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      setsWon: json['sets_won'] as int? ?? 0,
      setsLost: json['sets_lost'] as int? ?? 0,
      pointsWon: json['points_won'] as int? ?? 0,
      pointsLost: json['points_lost'] as int? ?? 0,
      leaguePoints: json['league_points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standing_id': standingId,
      'season_id': seasonId,
      'team_id': teamId,
      'matches_played': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'sets_won': setsWon,
      'sets_lost': setsLost,
      'points_won': pointsWon,
      'points_lost': pointsLost,
      'league_points': leaguePoints,
    };
  }

  LeagueStanding copyWith({
    int? standingId,
    int? seasonId,
    int? teamId,
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? setsWon,
    int? setsLost,
    int? pointsWon,
    int? pointsLost,
    int? leaguePoints,
  }) {
    return LeagueStanding(
      standingId: standingId ?? this.standingId,
      seasonId: seasonId ?? this.seasonId,
      teamId: teamId ?? this.teamId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      setsWon: setsWon ?? this.setsWon,
      setsLost: setsLost ?? this.setsLost,
      pointsWon: pointsWon ?? this.pointsWon,
      pointsLost: pointsLost ?? this.pointsLost,
      leaguePoints: leaguePoints ?? this.leaguePoints,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeagueStanding &&
          runtimeType == other.runtimeType &&
          standingId == other.standingId;

  @override
  int get hashCode => standingId.hashCode;

  @override
  String toString() {
    return 'LeagueStanding{standingId: $standingId, seasonId: $seasonId, teamId: $teamId, matchesPlayed: $matchesPlayed, wins: $wins, losses: $losses, leaguePoints: $leaguePoints}';
  }
}
