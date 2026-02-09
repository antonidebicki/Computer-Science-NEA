import '../../core/models/team.dart';
import '../../core/models/team_member.dart';
import '../api_client.dart';
import '../../core/logger.dart';

/// Repository for team and membership data
class TeamRepository {
  final ApiClient _apiClient;

  TeamRepository(this._apiClient);

  Future<List<Team>> getTeams() async {
    final data = await _apiClient.get('/api/teams');
    return (data as List).map((json) => Team.fromJson(json)).toList();
  }

  Future<List<TeamMember>> getTeamMembers(int teamId) async {
    final data = await _apiClient.get('/api/teams/$teamId/members');
    return (data as List).map((json) => TeamMember.fromJson(json)).toList();
  }

  Future<TeamMember> updateTeamMemberNumber({
    required int teamId,
    required int userId,
    required int playerNumber,
  }) async {
    final data = await _apiClient.put(
      '/api/teams/$teamId/members/$userId',
      {'player_number': playerNumber},
    );

    return TeamMember.fromJson(data as Map<String, dynamic>);
  }

  Future<Team> createTeam({
    required String name,
    required int createdByUserId,
    String? logoUrl,
  }) async {
    final payload = {
      'name': name,
      'created_by_user_id': createdByUserId,
      if (logoUrl != null && logoUrl.trim().isNotEmpty) 'logo_url': logoUrl,
    };

    final data = await _apiClient.post('/api/teams', payload);
    return Team.fromJson(data as Map<String, dynamic>);
  }

  /// Returns the first team the user belongs to, or null if they are not on a team
  Future<Team?> getTeamForUser(int userId) async {
    final teams = await getTeams();

    for (final team in teams) {
      if (team.createdByUserId == userId) {
        return team;
      }
      try {
        final members = await getTeamMembers(team.teamId);
        if (members.any((member) => member.userId == userId)) {
          return team;
        }
      } catch (e) {
        // Keep looking even if one team lookup fails
        Log.e('Error checking team ${team.teamId} members: $e');
      }
    }

    return null;
  }

  /// Returns all teams the user belongs to
  Future<List<Team>> getTeamsForUser(int userId) async {
    final teams = await getTeams();
    final userTeams = <Team>[];
    final seenTeamIds = <int>{};

    for (final team in teams) {
      if (team.createdByUserId == userId && !seenTeamIds.contains(team.teamId)) {
        userTeams.add(team);
        seenTeamIds.add(team.teamId);
      }
      try {
        final members = await getTeamMembers(team.teamId);
        if (members.any((member) => member.userId == userId)) {
          if (!seenTeamIds.contains(team.teamId)) {
            userTeams.add(team);
            seenTeamIds.add(team.teamId);
          }
        }
      } catch (e) {
        // Keep looking even if one team lookup fails
        Log.e('Error checking team ${team.teamId} members: $e');
      }
    }

    return userTeams;
  }
}
