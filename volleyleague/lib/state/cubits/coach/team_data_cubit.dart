import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../services/api_client.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/season.dart';
import '../../../core/models/team_member.dart';
import 'team_data_state.dart';

class TeamDataCubit extends Cubit<TeamDataState> {
  final LeagueRepository _leagueRepository;
  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;
  final int userId;

  TeamDataCubit({
    required LeagueRepository leagueRepository,
    required MatchRepository matchRepository,
    TeamRepository? teamRepository,
    required this.userId,
  })  : _leagueRepository = leagueRepository,
        _matchRepository = matchRepository,
        _teamRepository = teamRepository ?? TeamRepository(ApiClient()),
        super(TeamDataInitial());

  Future<void> loadTeamData() async {
    try {
      emit(TeamDataLoading());
      if (userId == 0) {
        emit(TeamDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
          coachedPlayers: const [],
          coachTeam: null,
        ));
        return;
      }

      final coachTeam = await _teamRepository.getTeamForUser(userId);

      if (coachTeam == null) {
        emit(TeamDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
          coachedPlayers: const [],
          coachTeam: null,
        ));
        return;
      }

      final leagues = await _leagueRepository.getLeagues();
      final coachTeams = await _teamRepository.getTeamsForUser(userId);
      Set<int> coachTeamIds = {};
      
      for (final team in coachTeams) {
        coachTeamIds.add(team.teamId);
        debugPrint('Coach team: ${team.name} (ID: ${team.teamId})');
      }

      List<LeagueStandingsInfo> leagueStandingsList = [];
      List<Season> allSeasons = [];
      Map<int, Map<int, String>> leagueSeasonTeamNames = {};

      for (final league in leagues) {
        final seasons = await _leagueRepository.getSeasons(league.leagueId);

        for (final season in seasons) {
          final teamsInSeason = await _leagueRepository.getSeasonTeams(season.seasonId);
          
          final hasCoachTeam = teamsInSeason.any(
            (team) => coachTeamIds.contains(team['team_id']),
          );

          if (hasCoachTeam) {
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
        // Load all players from coached teams even if no standings
        List<TeamMember> allCoachedPlayers = [];
        
        try {
          for (final teamId in coachTeamIds) {
            final players = await _teamRepository.getTeamMembers(teamId);
            allCoachedPlayers.addAll(players);
            debugPrint('Loaded ${players.length} players from team $teamId');
          }
          // Remove duplicates by userId
          final uniquePlayers = <int, TeamMember>{};
          for (final player in allCoachedPlayers) {
            uniquePlayers[player.userId] = player;
          }
          allCoachedPlayers = uniquePlayers.values.toList();
          debugPrint('Total unique coached players: ${allCoachedPlayers.length}');
        } catch (e) {
          debugPrint('Error loading coached players: $e');
        }
        
        emit(TeamDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
          coachedPlayers: allCoachedPlayers,
          coachTeam: coachTeam,
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
            final isCoachMatch = coachTeamIds.contains(match.homeTeamId) || 
                 coachTeamIds.contains(match.awayTeamId);
            debugPrint('Match: ${match.homeTeamId} vs ${match.awayTeamId}, isCoachMatch: $isCoachMatch');
            
            // dont change bc if you do there will be hundreds of fixtures loaded for every coach
            if (isCoachMatch && match.matchDatetime != null) {
              allUpcomingFixtures.add(MatchData(
                match: match,
                homeTeamName: teamNames[match.homeTeamId] ?? 'Unknown',
                awayTeamName: teamNames[match.awayTeamId] ?? 'Unknown',
              ));
            }
          }
        }

        debugPrint('Total fixtures loaded: ${allUpcomingFixtures.length}');

        allUpcomingFixtures.sort((a, b) {
          if (a.match.matchDatetime == null && b.match.matchDatetime == null) return 0;
          if (a.match.matchDatetime == null) return 1;
          if (b.match.matchDatetime == null) return -1;
          return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
        });
      } catch (e) {
        debugPrint('Error loading fixtures: $e');
      }

      // Load all players from coached teams
      List<TeamMember> allCoachedPlayers = [];
      
      try {
        for (final teamId in coachTeamIds) {
          final players = await _teamRepository.getTeamMembers(teamId);
          allCoachedPlayers.addAll(players);
          debugPrint('Loaded ${players.length} players from team $teamId');
        }
        // Remove duplicates by userId
        final uniquePlayers = <int, TeamMember>{};
        for (final player in allCoachedPlayers) {
          uniquePlayers[player.userId] = player;
        }
        allCoachedPlayers = uniquePlayers.values.toList();
        debugPrint('Total unique coached players: ${allCoachedPlayers.length}');
      } catch (e) {
        debugPrint('Error loading coached players: $e');
      }

      if (!isClosed) {
        emit(TeamDataLoaded(
          leagueStandings: leagueStandingsList,
          upcomingFixtures: allUpcomingFixtures,
          coachedPlayers: allCoachedPlayers,
          coachTeam: coachTeam,
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading team data: $e');
      debugPrint('$stackTrace');
      if (!isClosed) {
        emit(TeamDataError('Failed to load data: ${e.toString()}'));
      }
    }
  }

  Future<void> refresh() => loadTeamData();
}
