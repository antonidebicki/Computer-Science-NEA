import '../../../core/models/league.dart';
import '../../../core/models/match_data.dart';

abstract class PlayerDataState {}

class PlayerDataInitial extends PlayerDataState {}

class PlayerDataLoading extends PlayerDataState {}

class LeagueStandingsInfo {
  final League league;
  final List<StandingData> standings;

  const LeagueStandingsInfo({
    required this.league,
    required this.standings,
  });
}

class PlayerDataLoaded extends PlayerDataState {
  final List<LeagueStandingsInfo> leagueStandings;
  final List<MatchData> upcomingFixtures;

  PlayerDataLoaded({
    required this.leagueStandings,
    required this.upcomingFixtures,
  });
}

class PlayerDataError extends PlayerDataState {
  final String message;

  PlayerDataError(this.message);
}

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
      points: json['league_points'] as int, 
    );
  }
}

