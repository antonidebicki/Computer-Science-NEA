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

  /// Returns the first team the user belongs to, or null if they are not on a team
  Future<Team?> getTeamForUser(int userId) async {
    final teams = await getTeams();

    for (final team in teams) {
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
}
