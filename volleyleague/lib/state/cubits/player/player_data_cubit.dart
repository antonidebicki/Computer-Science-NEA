import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/season.dart';
import 'player_data_state.dart';

// maybe will turn into a bloc one day but too complicated for now
//i only have 50 hours 
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

  Future<void> loadPlayerData() async {
    try {
      emit(PlayerDataLoading());
      if (userId == 0) {
        emit(PlayerDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

      final playerTeam = await _teamRepository.getTeamForUser(userId);

      if (playerTeam == null) {
        emit(PlayerDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

      final leagues = await _leagueRepository.getLeagues();
      
      // Get all teams for this player
      final playerTeams = await _teamRepository.getTeamsForUser(userId);
      Set<int> playerTeamIds = {};
      
      for (final team in playerTeams) {
        playerTeamIds.add(team.teamId);
        debugPrint('Player team: ${team.name} (ID: ${team.teamId})');
      }

      List<LeagueStandingsInfo> leagueStandingsList = [];
      List<Season> allSeasons = [];
      Map<int, Map<int, String>> leagueSeasonTeamNames = {}; // seasonId -> (teamId -> teamName)

      for (final league in leagues) {
        final seasons = await _leagueRepository.getSeasons(league.leagueId);

        for (final season in seasons) {
          final teamsInSeason = await _leagueRepository.getSeasonTeams(season.seasonId);
          
          final hasPlayerTeam = teamsInSeason.any(
            (team) => playerTeamIds.contains(team['team_id']),
          );

          if (hasPlayerTeam) {
            allSeasons.add(season);
            leagueSeasonTeamNames[season.seasonId] = {};
            for (final teamJson in teamsInSeason) {
              leagueSeasonTeamNames[season.seasonId]![teamJson['team_id'] as int] = 
                  teamJson['team_name'] as String;
            }
            debugPrint('Added season: ${season.name} (ID: ${season.seasonId}) for league: ${league.name}');

            try {
              final standingsJson = await _leagueRepository.getStandings(
                season.seasonId,
                archived: false,
              );
              final standings = standingsJson.map((json) => StandingData.fromJson(json)).toList();
              standings.sort((a, b) => b.points.compareTo(a.points));
              
              leagueStandingsList.add(LeagueStandingsInfo(
                league: league,
                standings: standings,
              ));
            } catch (e) {
              debugPrint('Error loading standings for ${league.name}: $e');
            }
          }
        }
      }

      if (leagueStandingsList.isEmpty) {
        emit(PlayerDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }


      List<MatchData> allUpcomingFixtures = [];

      try {
        for (final season in allSeasons) {
          final matches = await _matchRepository.getMatches(
            seasonId: season.seasonId,
            status: GameState.scheduled.value,
          );

          final teamNames = leagueSeasonTeamNames[season.seasonId] ?? {};
          debugPrint('Season ${season.seasonId} has ${matches.length} scheduled matches');

          for (final match in matches) {
            final isPlayerMatch = playerTeamIds.contains(match.homeTeamId) || 
                 playerTeamIds.contains(match.awayTeamId);
            debugPrint('Match: ${match.homeTeamId} vs ${match.awayTeamId}, isPlayerMatch: $isPlayerMatch');
            
            // dont change bc if you do there will be hundreds of fixtures loaded for every player
            if (isPlayerMatch && match.matchDatetime != null) {
              allUpcomingFixtures.add(MatchData(
                match: match,
                homeTeamName: teamNames[match.homeTeamId] ?? 'Unknown',
                awayTeamName: teamNames[match.awayTeamId] ?? 'Unknown',
              ));
            }
          }
        }

        debugPrint('Total fixtures loaded: ${allUpcomingFixtures.length}');

        // Sort all fixtures chronologically
        allUpcomingFixtures.sort((a, b) {
          if (a.match.matchDatetime == null && b.match.matchDatetime == null) return 0;
          if (a.match.matchDatetime == null) return 1;
          if (b.match.matchDatetime == null) return -1;
          return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
        });
      } catch (e) {
        debugPrint('Error loading fixtures: $e');
      }

      if (!isClosed) {
        emit(PlayerDataLoaded(
          leagueStandings: leagueStandingsList,
          upcomingFixtures: allUpcomingFixtures,
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading player data: $e');
      debugPrint('$stackTrace');
      if (!isClosed) {
        emit(PlayerDataError('Failed to load data: ${e.toString()}'));
      }
    }
  }

  Future<void> refresh() => loadPlayerData();
}
