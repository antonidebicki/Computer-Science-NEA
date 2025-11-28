import '../../../core/models/league.dart';
import '../../../core/models/match.dart';

/// Base state for player data
abstract class PlayerDataState {}

/// Initial state
class PlayerDataInitial extends PlayerDataState {}

/// Loading state
class PlayerDataLoading extends PlayerDataState {}

/// Successfully loaded data
class PlayerDataLoaded extends PlayerDataState {
  final League? league;
  final List<StandingData> standings;
  final List<MatchData> upcomingFixtures;

  PlayerDataLoaded({
    this.league,
    required this.standings,
    required this.upcomingFixtures,
  });
}

/// Error state
class PlayerDataError extends PlayerDataState {
  final String message;

  PlayerDataError(this.message);
}

/// Data model for standings
class StandingData {
  final int teamId;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int points;

  StandingData({
    required this.teamId,
    required this.teamName,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.points,
  });

  factory StandingData.fromJson(Map<String, dynamic> json) {
    return StandingData(
      teamId: json['team_id'] as int,
      teamName: json['team_name'] as String,
      matchesPlayed: json['matches_played'] as int,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      points: json['league_points'] as int, // API uses 'league_points' field
    );
  }
}

/// Data model for match with team names
class MatchData {
  final Match match;
  final String homeTeamName;
  final String awayTeamName;

  MatchData({
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
  });
}
