import '../../../core/models/league.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/season.dart';

abstract class PlayerDataState {}

class PlayerDataInitial extends PlayerDataState {}

class PlayerDataLoading extends PlayerDataState {}

class LeagueStandingsInfo {
  final League league;
  final Season season;
  final List<StandingData> standings;

  const LeagueStandingsInfo({
    required this.league,
    required this.season,
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
  
  // Helper to get unique leagues where user participates
  List<League> get uniqueLeagues {
    final seen = <int>{};
    return leagueStandings
        .where((info) => seen.add(info.league.leagueId))
        .map((info) => info.league)
        .toList();
  }
  
  // Helper to get seasons for a specific league where user participates
  List<Season> getSeasonsForLeague(int leagueId) {
    return leagueStandings
        .where((info) => info.league.leagueId == leagueId)
        .map((info) => info.season)
        .toList();
  }
  
  // Helper to get standings for a specific season
  List<StandingData>? getStandingsForSeason(int seasonId) {
    try {
      return leagueStandings
          .firstWhere((info) => info.season.seasonId == seasonId)
          .standings;
    } catch (e) {
      return null;
    }
  }
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
  final int setsWon;
  final int setsLost;
  final int setDiff;
  final int pointsWon;
  final int pointsLost;
  final int pointDiff;

  StandingData({
    required this.teamId,
    required this.teamName,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.points,
    required this.setsWon,
    required this.setsLost,
    required this.setDiff,
    required this.pointsWon,
    required this.pointsLost,
    required this.pointDiff,
  });

  factory StandingData.fromJson(Map<String, dynamic> json) {
    return StandingData(
      teamId: json['team_id'] as int,
      teamName: json['team_name'] as String,
      matchesPlayed: json['matches_played'] as int,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      points: json['league_points'] as int,
      setsWon: json['sets_won'] as int? ?? 0,
      setsLost: json['sets_lost'] as int? ?? 0,
      setDiff: json['set_diff'] as int? ?? 0,
      pointsWon: json['points_won'] as int? ?? 0,
      pointsLost: json['points_lost'] as int? ?? 0,
      pointDiff: json['point_diff'] as int? ?? 0,
    );
  }
}

