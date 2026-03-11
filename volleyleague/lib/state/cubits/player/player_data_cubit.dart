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

  PlayerDataCubit({required this.userId})
    : _apiClient = ApiClient(),
      super(PlayerDataInitial());

  Future<void> loadPlayerData() async {
    try {
      emit(PlayerDataLoading());
      if (userId == 0) {
        emit(
          PlayerDataLoaded(
            leagueStandings: const [],
            upcomingFixtures: const [],
          ),
        );
        return;
      }

      // this is a new call to make the home screen load wayyy faster, from approx 10s to 500ms
      final homeData = await _apiClient.get('/api/users/home-data');

      if (homeData == null) {
        emit(
          PlayerDataLoaded(
            leagueStandings: const [],
            upcomingFixtures: const [],
            playerTeamIds: const [],
          ),
        );
        return;
      }

      // Extract player team IDs from the API response
      final playerTeamIdsList =
          (homeData['player_team_ids'] as List?)?.cast<int>() ?? [];

      final seasonsData = homeData['seasons_data'] as List?;
      if (seasonsData == null || seasonsData.isEmpty) {
        emit(
          PlayerDataLoaded(
            leagueStandings: const [],
            upcomingFixtures: const [],
            playerTeamIds: playerTeamIdsList,
          ),
        );
        return;
      }

      List<LeagueStandingsInfo> leagueStandingsList = [];
      List<MatchData> allUpcomingFixtures = [];

      for (final seasonData in seasonsData) {
        final seasonId = seasonData['season_id'] as int;
        final leagueId = seasonData['league_id'] as int;
        final seasonName = seasonData['season_name'] as String;
        final leagueName = seasonData['league_name'] as String;

        final season = Season(
          seasonId: seasonId,
          leagueId: leagueId,
          name: seasonName,
          startDate: DateTime.now(),
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
          adminUserId: 0,
          description: null,
          rules: null,
          createdAt: DateTime.now(),
        );

        final standingsJson = seasonData['standings'] as List?;
        final standings =
            standingsJson?.map((json) {
              return StandingData.fromJson(json as Map<String, dynamic>);
            }).toList() ??
            [];

        leagueStandingsList.add(
          LeagueStandingsInfo(
            league: league,
            season: season,
            standings: standings,
          ),
        );

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

      allUpcomingFixtures.sort((a, b) {
        if (a.match.matchDatetime == null && b.match.matchDatetime == null) {
          return 0;
        }
        if (a.match.matchDatetime == null) return 1;
        if (b.match.matchDatetime == null) return -1;
        return a.match.matchDatetime!.compareTo(b.match.matchDatetime!);
      });

      if (!isClosed) {
        emit(
          PlayerDataLoaded(
            leagueStandings: leagueStandingsList,
            upcomingFixtures: allUpcomingFixtures,
            playerTeamIds: playerTeamIdsList,
          ),
        );
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
