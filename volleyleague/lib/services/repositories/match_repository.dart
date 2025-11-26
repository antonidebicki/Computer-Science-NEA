import '../../core/models/match.dart';
import '../../core/models/volleyball_set.dart';
import '../api_client.dart';


class MatchRepository {
  final ApiClient _apiClient;

  MatchRepository(this._apiClient);

  Future<List<Match>> getMatches({
    int? seasonId,
    int? teamId,
    String? status,
  }) async {
    var endpoint = '/api/matches';
    final queryParams = <String>[];

    if (seasonId != null) queryParams.add('season_id=$seasonId');
    if (teamId != null) queryParams.add('team_id=$teamId');
    if (status != null) queryParams.add('status=$status');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final data = await _apiClient.get(endpoint);
    return (data as List).map((json) => Match.fromJson(json)).toList();
  }

  Future<Match> getMatch(int matchId) async {
    final data = await _apiClient.get('/api/matches/$matchId');
    return Match.fromJson(data);
  }

  Future<Match> createMatch({
    required int seasonId,
    required int homeTeamId,
    required int awayTeamId,
    DateTime? matchDatetime,
    String? venue,
  }) async {
    final data = await _apiClient.post('/api/matches', {
      'season_id': seasonId,
      'home_team_id': homeTeamId,
      'away_team_id': awayTeamId,
      if (matchDatetime != null)
        'match_datetime': matchDatetime.toIso8601String(),
      if (venue != null) 'venue': venue,
    });
    return Match.fromJson(data);
  }

  Future<Match> updateMatch({
    required int matchId,
    String? status,
    int? winnerTeamId,
    int? homeSetsWon,
    int? awaySetsWon,
  }) async {
    final data = await _apiClient.put('/api/matches/$matchId', {
      if (status != null) 'status': status,
      if (winnerTeamId != null) 'winner_team_id': winnerTeamId,
      if (homeSetsWon != null) 'home_sets_won': homeSetsWon,
      if (awaySetsWon != null) 'away_sets_won': awaySetsWon,
    });
    return Match.fromJson(data);
  }

  Future<void> deleteMatch(int matchId) async {
    await _apiClient.delete('/api/matches/$matchId');
  }

  Future<List<VolleyballSet>> getMatchSets(int matchId) async {
    final data = await _apiClient.get('/api/matches/$matchId/sets');
    return (data as List).map((json) => VolleyballSet.fromJson(json)).toList();
  }

  Future<VolleyballSet> createSet({
    required int matchId,
    required int setNumber,
    required int homeTeamScore,
    required int awayTeamScore,
  }) async {
    final data = await _apiClient.post('/api/matches/$matchId/sets', {
      'set_number': setNumber,
      'home_team_score': homeTeamScore,
      'away_team_score': awayTeamScore,
    });
    return VolleyballSet.fromJson(data);
  }

  Future<VolleyballSet> updateSet({
    required int matchId,
    required int setId,
    required int homeTeamScore,
    required int awayTeamScore,
  }) async {
    final data = await _apiClient.put('/api/matches/$matchId/sets/$setId', {
      'home_team_score': homeTeamScore,
      'away_team_score': awayTeamScore,
    });
    return VolleyballSet.fromJson(data);
  }

  /// Call after all sets are recorded.
  Future<void> submitMatchScore({
    required int matchId,
    required int homeSetsWon,
    required int awaySetsWon,
    required int homePoints,
    required int awayPoints,
  }) async {
    await _apiClient.post('/api/matches/$matchId/submit-score', {
      'home_sets_won': homeSetsWon,
      'away_sets_won': awaySetsWon,
      'home_points': homePoints,
      'away_points': awayPoints,
    });
  }

  /// Updates standings. Should be called by ADMIN/REFEREE after match is complete.
  Future<Map<String, dynamic>> processMatch(int matchId) async {
    final data = await _apiClient.post('/api/matches/process', {
      'match_id': matchId,
    });
    return data;
  }

  Future<Map<String, dynamic>> generateFixtures({
    required int seasonId,
    required String startDate,
    int matchesPerWeekPerTeam = 1,
    int weeksBetweenMatches = 1,
    bool doubleRoundRobin = false,
    List<int>? allowedWeekdays,
  }) async {
    final data = await _apiClient.post('/api/seasons/$seasonId/generate-fixtures', {
      'start_date': startDate,
      'matches_per_week_per_team': matchesPerWeekPerTeam,
      'weeks_between_matches': weeksBetweenMatches,
      'double_round_robin': doubleRoundRobin,
      if (allowedWeekdays != null) 'allowed_weekdays': allowedWeekdays,
    });
    return data;
  }
}
