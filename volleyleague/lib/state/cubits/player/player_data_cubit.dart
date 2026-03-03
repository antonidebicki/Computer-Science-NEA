import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/season.dart';
import '../../../core/models/match_data.dart';
import '../../../core/models/league.dart';
import '../../../core/models/match.dart';
import 'player_data_state.dart';

// maybe will turn into a bloc one day but too complicated for now
//i only have 50 hours 
class PlayerDataCubit extends Cubit<PlayerDataState> {
  final ApiClient _apiClient;
  final int userId;

  PlayerDataCubit({
    required this.userId,
  })  : _apiClient = ApiClient(),
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

      // NEW: Call consolidated endpoint that returns all home screen data in 1 call
      // This replaces 35+ individual API calls
      final homeData = await _apiClient.get('/api/users/home-data');
      
      if (homeData == null) {
        emit(PlayerDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
        ));
        return;
      }

      final seasonsData = homeData['seasons_data'] as List?;
      if (seasonsData == null || seasonsData.isEmpty) {
        emit(PlayerDataLoaded(
          leagueStandings: const [],
          upcomingFixtures: const [],
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

        // Transform fixtures (limit to 5 per season)
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
