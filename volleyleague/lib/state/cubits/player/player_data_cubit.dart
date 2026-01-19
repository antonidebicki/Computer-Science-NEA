import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../../../core/models/league.dart';
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
          league: null,
          standings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

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
      //vs says this is unused. do not delete for some reason its being dumb
      List<Map<String, dynamic>>? seasonTeams;

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
        
        standings.sort((a, b) => b.points.compareTo(a.points));
      } catch (e) {
        debugPrint('Error loading standings: $e');
      }

      List<MatchData> allUpcomingFixtures = [];

      try {
        List<Season> playerSeasons = [];
        Map<int, Map<int, String>> leagueSeasonTeamNames = {}; // seasonId -> (teamId -> teamName)

        for (final league in leagues) {
          final seasons = await _leagueRepository.getSeasons(league.leagueId);

          for (final season in seasons) {
            final teamsInSeason = await _leagueRepository.getSeasonTeams(season.seasonId);
            final isInSeason = teamsInSeason.any(
              (team) => team['team_id'] == playerTeam.teamId,
            );

            if (isInSeason) {
              playerSeasons.add(season);
              leagueSeasonTeamNames[season.seasonId] = {};
              for (final teamJson in teamsInSeason) {
                leagueSeasonTeamNames[season.seasonId]![teamJson['team_id'] as int] = 
                    teamJson['team_name'] as String;
              }
            }
          }
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        for (final season in playerSeasons) {
          final matches = await _matchRepository.getMatches(
            seasonId: season.seasonId,
            status: GameState.scheduled.value,
          );

          final teamNames = leagueSeasonTeamNames[season.seasonId] ?? {};

          for (final match in matches) {
            if (match.matchDatetime != null && match.matchDatetime!.isAfter(today)) {
              allUpcomingFixtures.add(MatchData(
                match: match,
                homeTeamName: teamNames[match.homeTeamId] ?? 'Unknown',
                awayTeamName: teamNames[match.awayTeamId] ?? 'Unknown',
              ));
            }
          }
        }

        allUpcomingFixtures.sort((a, b) {
          if (a.match.matchDatetime == null && b.match.matchDatetime == null) return 0;
          if (a.match.matchDatetime == null) return 1;
          if (b.match.matchDatetime == null) return -1;
          return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
        });

        allUpcomingFixtures = allUpcomingFixtures.take(5).toList();
      } catch (e) {
        debugPrint('Error loading fixtures: $e');
      }

      emit(PlayerDataLoaded(
        league: userLeague,
        standings: standings,
        upcomingFixtures: allUpcomingFixtures,
      ));
    } catch (e, stackTrace) {
      debugPrint('Error loading player data: $e');
      debugPrint('$stackTrace');
      emit(PlayerDataError('Failed to load data: ${e.toString()}'));
    }
  }

  Future<void> refresh() => loadPlayerData();
}
