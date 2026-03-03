import '../../../core/models/league.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/season.dart';
import '../../../core/models/team.dart';
import '../../../core/models/team_member.dart';
import '../player/player_data_state.dart' show StandingData;

// Re-export StandingData so it's available to files that import team_data_state
export '../player/player_data_state.dart' show StandingData;

abstract class TeamDataState {}

class TeamDataInitial extends TeamDataState {}

class TeamDataLoading extends TeamDataState {}

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

class TeamDataLoaded extends TeamDataState {
  final List<LeagueStandingsInfo> leagueStandings;
  final List<MatchData> upcomingFixtures;
  final List<TeamMember> coachedPlayers;
  final Team? coachTeam;

  TeamDataLoaded({
    required this.leagueStandings,
    required this.upcomingFixtures,
    required this.coachedPlayers,
    required this.coachTeam,
  });
  
  // Helper to get unique leagues where coach's team participates
  List<League> get uniqueLeagues {
    final seen = <int>{};
    return leagueStandings
        .where((info) => seen.add(info.league.leagueId))
        .map((info) => info.league)
        .toList();
  }
  
  // Helper to get seasons for a specific league where coach's team participates
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

class TeamDataError extends TeamDataState {
  final String message;

  TeamDataError(this.message);
}

