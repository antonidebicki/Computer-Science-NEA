import '../../core/models/invitation.dart';
import '../api_client.dart';

/// Repository for invitation code and team join request operations
class InvitationRepository {
  final ApiClient _apiClient;

  InvitationRepository(this._apiClient);

  /// Generate today's invitation code for the current user
  Future<InvitationCode> generateInvitationCode() async {
    final response = await _apiClient.get('/api/users/invitation-code/generate');
    return InvitationCode.fromJson(response);
  }

  /// Generate today's invitation code for a team (coach/admin action)
  Future<TeamInvitationCode> generateTeamInvitationCode(int teamId) async {
    final response = await _apiClient.get(
      '/api/teams/invitation-code/generate?team_id=$teamId',
    );
    return TeamInvitationCode.fromJson(response);
  }

  /// Redeem an invitation code (legacy - creates connection between users)
  /// Note: This is the old flow that just logs the invitation redemption
  Future<InvitationRedeemResponse> redeemInvitationCode(
      String invitationCode) async {
    final response = await _apiClient.post(
      '/api/users/invitation-code/redeem',
      {'invitation_code': invitationCode},
    );
    return InvitationRedeemResponse.fromJson(response);
  }

  /// Create a team invitation using a player's invitation code (ADMIN/COACH action)
  /// Flow:
  /// - Player generates and shares their invitation code
  /// - Admin enters player's code and team ID
  /// - Invitation is created with PENDING status
  /// - Player receives invitation and can accept/reject
  Future<TeamJoinRequest> createTeamInvitation(
      CreateTeamInvitationRequest request) async {
    final response = await _apiClient.post(
      '/api/teams/invitations',
      request.toJson(),
    );
    return TeamJoinRequest.fromJson(response);
  }

  /// Get pending invitations sent by the current user (Admin/Coach checking sent invitations)
  Future<List<TeamJoinRequest>> getSentInvitations({int? teamId}) async {
    final queryParams = teamId != null ? '?team_id=$teamId' : '';
    final response =
        await _apiClient.get('/api/teams/invitations/sent$queryParams');

    final List<dynamic> requestsList = response['invitations'] as List<dynamic>;
    return requestsList
        .map((json) => TeamJoinRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get invitations received by the current user (PLAYER checking their invitations)
  Future<List<TeamJoinRequest>> getMyInvitations() async {
    final response = await _apiClient.get('/api/teams/invitations/received');
    
    final List<dynamic> requestsList = response['invitations'] as List<dynamic>;
    return requestsList
        .map((json) => TeamJoinRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Accept or reject a team invitation (PLAYER action)
  /// If accepted, the player is added to the team
  Future<TeamJoinRequest> respondToInvitation({
    required int joinRequestId,
    required RespondToInvitationRequest response,
  }) async {
    final responseData = await _apiClient.post(
      '/api/teams/invitations/$joinRequestId/respond',
      response.toJson(),
    );
    return TeamJoinRequest.fromJson(responseData);
  }

  /// Delete/cancel an invitation
  /// Admin can cancel sent invitations, player can decline pending invitations
  Future<void> deleteInvitation(int joinRequestId) async {
    await _apiClient.delete('/api/teams/invitations/$joinRequestId');
  }

  /// Create a league invitation for a team (ADMIN action)
  Future<LeagueJoinRequest> createLeagueInvitation(
      CreateLeagueInvitationRequest request) async {
    final response = await _apiClient.post(
      '/api/leagues/invitations',
      request.toJson(),
    );
    return LeagueJoinRequest.fromJson(response);
  }

  /// Get league invitations sent by the current admin
  Future<List<LeagueJoinRequest>> getSentLeagueInvitations({
    int? leagueId,
    int? seasonId,
  }) async {
    final queryParams = <String>[];
    if (leagueId != null) queryParams.add('league_id=$leagueId');
    if (seasonId != null) queryParams.add('season_id=$seasonId');
    final queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

    final response =
        await _apiClient.get('/api/leagues/invitations/sent$queryString');
    final List<dynamic> requestsList = response['invitations'] as List<dynamic>;
    return requestsList
        .map((json) => LeagueJoinRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get league invitations received by teams owned by current user
  Future<List<LeagueJoinRequest>> getReceivedLeagueInvitations() async {
    final response = await _apiClient.get('/api/leagues/invitations/received');
    final List<dynamic> requestsList = response['invitations'] as List<dynamic>;
    return requestsList
        .map((json) => LeagueJoinRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Accept or reject a league invitation (team admin/coach action)
  Future<LeagueJoinRequest> respondToLeagueInvitation({
    required int joinRequestId,
    required RespondToLeagueInvitationRequest response,
  }) async {
    final responseData = await _apiClient.post(
      '/api/leagues/invitations/$joinRequestId/respond',
      response.toJson(),
    );
    return LeagueJoinRequest.fromJson(responseData);
  }

  /// Delete/cancel a league invitation
  Future<void> deleteLeagueInvitation(int joinRequestId) async {
    await _apiClient.delete('/api/leagues/invitations/$joinRequestId');
  }
}