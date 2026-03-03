import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../services/repositories/team_repository.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/season.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/league.dart';
import '../../../core/models/match.dart';
import '../../../core/models/team_member.dart';
import '../player/player_data_state.dart' show StandingData;
import 'team_data_state.dart';

class TeamDataCubit extends Cubit<TeamDataState> {
  final ApiClient _apiClient;
  final TeamRepository _teamRepository;
  final int userId;

  TeamDataCubit({
    required this.userId,
  })  : _apiClient = ApiClient(),
        _teamRepository = TeamRepository(ApiClient()),
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
          coachTeamIds: const [],
        ));
        return;
      }

      // Consolidated coach home data endpoint - replaces 35+ API calls with 1
      final homeData = await _apiClient.get('/api/coaches/home-data');
      
      if (homeData == null) {
        emit(TeamDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
          coachedPlayers: const [],
          coachTeam: null,
          coachTeamIds: const [],
        ));
        return;
      }

      final seasonsData = homeData['seasons_data'] as List?;
      final coachTeamIds = (homeData['coach_team_ids'] as List?)?.cast<int>() ?? [];
      
      if (seasonsData == null || seasonsData.isEmpty) {
        emit(TeamDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
          coachedPlayers: const [],
          coachTeam: null,
          coachTeamIds: coachTeamIds,
        ));
        return;
      }

      // Transform API response to existing data structures
      List<LeagueStandingsInfo> leagueStandingsList = [];
      List<MatchData> allUpcomingFixtures = [];

      for (final seasonData in seasonsData) {
        final seasonId = seasonData['season_id'] as int;
        final leagueId = seasonData['league_id'] as int;
        final seasonName = seasonData['season_name'] as String;
        final leagueName = seasonData['league_name'] as String;
        
        // Create season and league objects
        final season = Season(
          seasonId: seasonId,
          leagueId: leagueId,
          name: seasonName,
          startDate: DateTime.now(), // Placeholder - from API we don't get these
          endDate: DateTime.now(),
          matchesPerWeekPerTeam: 1,
          weeksBetweenMatches: 1,
          doubleRoundRobin: false,
          allowedWeekdays: const [1, 3, 5],
          isArchived: false,
        );

        final league = League(
          leagueId: leagueId,
          name: leagueName,
          adminUserId: 0, // Not needed for display
          description: null,
          rules: null,
          createdAt: DateTime.now(),
        );

        // Transform standings
        final standingsJson = seasonData['standings'] as List?;
        final standings = standingsJson?.map((json) {
          return StandingData.fromJson(json as Map<String, dynamic>);
        }).toList() ?? [];

        leagueStandingsList.add(LeagueStandingsInfo(
          league: league,
          season: season,
          standings: standings,
        ));

        // Transform fixtures
        final fixturesJson = seasonData['upcoming_fixtures'] as List?;
        if (fixturesJson != null) {
          for (final fixtureJson in fixturesJson) {
            final fixture = fixtureJson as Map<String, dynamic>;
            final match = Match(
              matchId: fixture['match_id'] as int,
              seasonId: fixture['season_id'] as int,
              homeTeamId: fixture['home_team_id'] as int,
              awayTeamId: fixture['away_team_id'] as int,
              matchDatetime: fixture['match_datetime'] != null 
                ? DateTime.parse(fixture['match_datetime'] as String)
                : null,
              venue: fixture['venue'] as String?,
              status: GameState.fromString(fixture['status'] as String),
            );
            
            final matchData = MatchData(
              match: match,
              homeTeamName: fixture['home_team_name'] as String,
              awayTeamName: fixture['away_team_name'] as String,
            );
            allUpcomingFixtures.add(matchData);
          }
        }
      }

      // Sort fixtures chronologically
      allUpcomingFixtures.sort((a, b) {
        if (a.match.matchDatetime == null && b.match.matchDatetime == null) return 0;
        if (a.match.matchDatetime == null) return 1;
        if (b.match.matchDatetime == null) return -1;
        return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
      });

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
          coachTeam: null, // Not needed for home screen display
          coachTeamIds: coachTeamIds,
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
