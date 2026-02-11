import '../../core/models/league.dart';
import '../../core/models/season.dart';
import '../api_client.dart';

class LeagueRepository {
  final ApiClient _apiClient;

  LeagueRepository(this._apiClient);

  Future<List<League>> getLeagues() async {
    final data = await _apiClient.get('/api/leagues');
    return (data as List).map((json) => League.fromJson(json)).toList();
  }

  Future<League> getLeague(int leagueId) async {
    final data = await _apiClient.get('/api/leagues/$leagueId');
    return League.fromJson(data);
  }

  Future<League> createLeague({
    required String name,
    required int adminUserId,
    String? description,
    String? rules,
  }) async {
    final data = await _apiClient.post('/api/leagues', {
      'name': name,
      'admin_user_id': adminUserId,
      'description': description,
      'rules': rules,
    });
    return League.fromJson(data);
  }

  Future<List<Season>> getSeasons(int leagueId) async {
    final data = await _apiClient.get('/api/leagues/$leagueId/seasons');
    return (data as List).map((json) => Season.fromJson(json)).toList();
  }

  Future<Season> getSeason(int seasonId) async {
    final data = await _apiClient.get('/api/seasons/$seasonId');
    return Season.fromJson(data);
  }

  Future<Season> createSeason({
    required int leagueId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    int matchesPerWeekPerTeam = 1,
    int weeksBetweenMatches = 1,
    bool doubleRoundRobin = false,
    List<int> allowedWeekdays = const [1, 3, 5],
  }) async {
    final data = await _apiClient.post('/api/seasons', {
      'league_id': leagueId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'matches_per_week_per_team': matchesPerWeekPerTeam,
      'weeks_between_matches': weeksBetweenMatches,
      'double_round_robin': doubleRoundRobin,
      'allowed_weekdays': allowedWeekdays,
    });
    return Season.fromJson(data);
  }

  Future<Season> updateSeason({
    required int seasonId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    int matchesPerWeekPerTeam = 1,
    int weeksBetweenMatches = 1,
    bool doubleRoundRobin = false,
    List<int> allowedWeekdays = const [1, 3, 5],
  }) async {
    final data = await _apiClient.put('/api/seasons/$seasonId', {
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'matches_per_week_per_team': matchesPerWeekPerTeam,
      'weeks_between_matches': weeksBetweenMatches,
      'double_round_robin': doubleRoundRobin,
      'allowed_weekdays': allowedWeekdays,
    });
    return Season.fromJson(data);
  }

  Future<void> deleteSeason(int seasonId) async {
    await _apiClient.delete('/api/seasons/$seasonId');
  }

  /// Get standings. Set [archived] to true for archived data.
  Future<List<Map<String, dynamic>>> getStandings(
    int seasonId, {
    bool archived = false,
  }) async {
    final endpoint = '/api/seasons/$seasonId/standings?archived=$archived';
    final data = await _apiClient.get(endpoint);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getSeasonTeams(int seasonId) async {
    final data = await _apiClient.get('/api/seasons/$seasonId/teams');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> addTeamToSeason({
    required int seasonId,
    required int teamId,
  }) async {
    await _apiClient.post('/api/seasons/$seasonId/teams/$teamId', {
      'team_id': teamId,
    });
  }

  Future<void> removeTeamFromSeason({
    required int seasonId,
    required int teamId,
  }) async {
    await _apiClient.delete('/api/seasons/$seasonId/teams/$teamId');
  }

  Future<Map<String, dynamic>> initializeStandings(int seasonId) async {
    final data = await _apiClient.post(
      '/api/seasons/$seasonId/initialize-standings',
      {},
    );
    return data;
  }

  Future<Map<String, dynamic>> recalculateStandings(int seasonId) async {
    final data = await _apiClient.post(
      '/api/seasons/$seasonId/recalculate-standings',
      {},
    );
    return data;
  }
}
