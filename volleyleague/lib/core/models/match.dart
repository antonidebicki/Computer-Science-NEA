import 'enums.dart';

/// Match model representing a volleyball match between two teams
class Match {
  final int matchId;
  final int seasonId;
  final int homeTeamId;
  final int awayTeamId;
  final DateTime? matchDatetime;
  final String? venue;
  final GameState status;
  final int? winnerTeamId;
  final int homeSetsWon;
  final int awaySetsWon;

  const Match({
    required this.matchId,
    required this.seasonId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.matchDatetime,
    this.venue,
    this.status = GameState.scheduled,
    this.winnerTeamId,
    this.homeSetsWon = 0,
    this.awaySetsWon = 0,
  });

  /// Create a Match from a JSON map
  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchId: json['match_id'] as int,
      seasonId: json['season_id'] as int,
      homeTeamId: json['home_team_id'] as int,
      awayTeamId: json['away_team_id'] as int,
      matchDatetime: json['match_datetime'] != null
          ? DateTime.parse(json['match_datetime'] as String)
          : null,
      venue: json['venue'] as String?,
      status: json['status'] != null
          ? GameState.fromString(json['status'] as String)
          : GameState.scheduled,
      winnerTeamId: json['winner_team_id'] as int?,
      homeSetsWon: json['home_sets_won'] as int? ?? 0,
      awaySetsWon: json['away_sets_won'] as int? ?? 0,
    );
  }

  /// Convert Match to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'season_id': seasonId,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      'match_datetime': matchDatetime?.toIso8601String(),
      'venue': venue,
      'status': status.value,
      'winner_team_id': winnerTeamId,
      'home_sets_won': homeSetsWon,
      'away_sets_won': awaySetsWon,
    };
  }

  /// Create a copy of Match with some fields replaced
  Match copyWith({
    int? matchId,
    int? seasonId,
    int? homeTeamId,
    int? awayTeamId,
    DateTime? matchDatetime,
    String? venue,
    GameState? status,
    int? winnerTeamId,
    int? homeSetsWon,
    int? awaySetsWon,
  }) {
    return Match(
      matchId: matchId ?? this.matchId,
      seasonId: seasonId ?? this.seasonId,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      matchDatetime: matchDatetime ?? this.matchDatetime,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      homeSetsWon: homeSetsWon ?? this.homeSetsWon,
      awaySetsWon: awaySetsWon ?? this.awaySetsWon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId;

  @override
  int get hashCode => matchId.hashCode;

  @override
  String toString() {
    return 'Match{matchId: $matchId, seasonId: $seasonId, homeTeamId: $homeTeamId, awayTeamId: $awayTeamId, status: $status, homeSetsWon: $homeSetsWon, awaySetsWon: $awaySetsWon}';
  }
}
