import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../../../core/models/league.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/season.dart';
import 'player_data_state.dart';

/// Cubit to manage player's league and fixture data
/// Fetches league standings and upcoming fixtures from the API
class PlayerDataCubit extends Cubit<PlayerDataState> {
  final LeagueRepository _leagueRepository;
  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;
  final int userId;

  PlayerDataCubit({
    required LeagueRepository leagueRepository,
    required MatchRepository matchRepository,
    TeamRepository? teamRepository,
    required this.userId,
  })  : _leagueRepository = leagueRepository,
        _matchRepository = matchRepository,
        _teamRepository = teamRepository ?? TeamRepository(ApiClient()),
        super(PlayerDataInitial());

  /// Load player's league data and upcoming fixtures
  Future<void> loadPlayerData() async {
    try {
      emit(PlayerDataLoading());

      if (userId == 0) {
        emit(PlayerDataLoaded(
          league: null,
          standings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

      // Find the team this player belongs to
      final playerTeam = await _teamRepository.getTeamForUser(userId);

      if (playerTeam == null) {
        emit(PlayerDataLoaded(
          league: null,
          standings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

      final leagues = await _leagueRepository.getLeagues();
      
      League? userLeague;
      Season? currentSeason;
      List<Map<String, dynamic>>? seasonTeams;

      // Find the first league/season that includes the player's team
      for (final league in leagues) {
        final seasons = await _leagueRepository.getSeasons(league.leagueId);

        for (final season in seasons) {
          final teamsInSeason = await _leagueRepository.getSeasonTeams(season.seasonId);
          final isInSeason = teamsInSeason.any(
            (team) => team['team_id'] == playerTeam.teamId,
          );

          if (isInSeason) {
            userLeague = league;
            currentSeason = season;
            seasonTeams = teamsInSeason;
            break;
          }
        }

        if (userLeague != null) break;
      }

      if (userLeague == null || currentSeason == null) {
        emit(PlayerDataLoaded(
          league: null,
          standings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

      List<StandingData> standings = [];
      try {
        final standingsJson = await _leagueRepository.getStandings(
          currentSeason.seasonId,
          archived: false,
        );
        standings = standingsJson.map((json) => StandingData.fromJson(json)).toList();
        
        // Sort by points descending
        standings.sort((a, b) => b.points.compareTo(a.points));
      } catch (e) {
        // Standings might not be initialized yet
        print('Error loading standings: $e');
      }

      List<MatchData> upcomingFixtures = [];

      // Fetch upcoming matches for this season
      try {
        final matches = await _matchRepository.getMatches(
          seasonId: currentSeason.seasonId,
          status: GameState.scheduled.value,
        );

        // Get team details for the season once
        final teamNames = <int, String>{};
        final seasonTeamsData =
            seasonTeams ?? await _leagueRepository.getSeasonTeams(currentSeason.seasonId);
        for (final teamJson in seasonTeamsData) {
          teamNames[teamJson['team_id'] as int] = teamJson['team_name'] as String;
        }

        final matchDataList = matches.map((match) {
          return MatchData(
            match: match,
            homeTeamName: teamNames[match.homeTeamId] ?? 'Unknown',
            awayTeamName: teamNames[match.awayTeamId] ?? 'Unknown',
          );
        }).toList();

        // Sort by date (earliest first) and take only next few matches
        matchDataList.sort((a, b) {
          if (a.match.matchDatetime == null && b.match.matchDatetime == null) return 0;
          if (a.match.matchDatetime == null) return 1;
          if (b.match.matchDatetime == null) return -1;
          return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
        });

        upcomingFixtures = matchDataList.take(5).toList();
      } catch (e) {
        print('Error loading fixtures: $e');
      }

      emit(PlayerDataLoaded(
        league: userLeague,
        standings: standings,
        upcomingFixtures: upcomingFixtures,
      ));
    } catch (e, stackTrace) {
      print('Error loading player data: $e');
      print(stackTrace);
      emit(PlayerDataError('Failed to load data: ${e.toString()}'));
    }
  }

  /// Refresh data
  Future<void> refresh() => loadPlayerData();
}
