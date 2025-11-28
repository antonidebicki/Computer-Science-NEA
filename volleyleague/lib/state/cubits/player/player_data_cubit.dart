import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/repositories/league_repository.dart';
import '../../../services/repositories/match_repository.dart';
import '../../../core/models/league.dart';
import '../../../core/models/enums.dart';
import 'player_data_state.dart';

/// Cubit to manage player's league and fixture data
/// Fetches league standings and upcoming fixtures from the API
class PlayerDataCubit extends Cubit<PlayerDataState> {
  final LeagueRepository _leagueRepository;
  final MatchRepository _matchRepository;
  final int userId;

  PlayerDataCubit({
    required LeagueRepository leagueRepository,
    required MatchRepository matchRepository,
    required this.userId,
  })  : _leagueRepository = leagueRepository,
        _matchRepository = matchRepository,
        super(PlayerDataInitial());

  /// Load player's league data and upcoming fixtures
  Future<void> loadPlayerData() async {
    try {
      emit(PlayerDataLoading());

      // Fetch all leagues (in a real app, filter by user's team membership)
      final leagues = await _leagueRepository.getLeagues();
      
      League? userLeague;
      List<StandingData> standings = [];
      List<MatchData> upcomingFixtures = [];

      if (leagues.isNotEmpty) {
        // For now, use the first league
        // TODO: In production, filter by user's actual team membership
        userLeague = leagues.first;

        // Get seasons for this league
        final seasons = await _leagueRepository.getSeasons(userLeague.leagueId);
        
        if (seasons.isNotEmpty) {
          // Use the most recent season
          final currentSeason = seasons.last;

          // Fetch standings
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

          // Fetch upcoming matches for this season
          try {
            final matches = await _matchRepository.getMatches(
              seasonId: currentSeason.seasonId,
              status: GameState.scheduled.value,
            );

            // Get team details for each match
            final teamCache = <int, String>{};
            final matchDataList = <MatchData>[];

            for (final match in matches) {
              // Cache team names to avoid duplicate API calls
              if (!teamCache.containsKey(match.homeTeamId)) {
                final teams = await _leagueRepository.getSeasonTeams(currentSeason.seasonId);
                for (final teamJson in teams) {
                  teamCache[teamJson['team_id'] as int] = teamJson['team_name'] as String;
                }
              }

              matchDataList.add(MatchData(
                match: match,
                homeTeamName: teamCache[match.homeTeamId] ?? 'Unknown',
                awayTeamName: teamCache[match.awayTeamId] ?? 'Unknown',
              ));
            }

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
        }
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
