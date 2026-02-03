/* 
flow works this way:
-user generates inv key
-admin uses key
-sends request in database 
-user accepts/rejects
-api is called if accepted
*/

class InvitationCode {
  final int userId;
  final String invitationCode;
  final String codeGeneratedDate;

  const InvitationCode({
    required this.userId,
    required this.invitationCode,
    required this.codeGeneratedDate,
  });

  factory InvitationCode.fromJson(Map<String, dynamic> json) {
    return InvitationCode(
      userId: json['user_id'] as int,
      invitationCode: json['invitation_code'] as String,
      codeGeneratedDate: json['code_generated_date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'invitation_code': invitationCode,
      'code_generated_date': codeGeneratedDate,
    };
  }
}

class InvitationRedeemResponse {
  final bool success;
  final String message;
  final int? senderUserId;
  final String? senderUsername;

  const InvitationRedeemResponse({
    required this.success,
    required this.message,
    this.senderUserId,
    this.senderUsername,
  });

  factory InvitationRedeemResponse.fromJson(Map<String, dynamic> json) {
    return InvitationRedeemResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      senderUserId: json['sender_user_id'] as int?,
      senderUsername: json['sender_username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'sender_user_id': senderUserId,
      'sender_username': senderUsername,
    };
  }
}

class TeamJoinRequest {
  final int joinRequestId;
  final int teamId;
  final int userId;
  final int invitedByUserId;
  final String invitationCode;
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED'
  final DateTime createdAt;
  final DateTime? respondedAt;
  
  final String? teamName;
  final String? invitedByUsername;
  final String? username;

  const TeamJoinRequest({
    required this.joinRequestId,
    required this.teamId,
    required this.userId,
    required this.invitedByUserId,
    required this.invitationCode,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.teamName,
    this.invitedByUsername,
    this.username,
  });

  factory TeamJoinRequest.fromJson(Map<String, dynamic> json) {
    return TeamJoinRequest(
      joinRequestId: json['join_request_id'] as int,
      teamId: json['team_id'] as int,
      userId: json['user_id'] as int,
      invitedByUserId: json['invited_by_user_id'] as int,
      invitationCode: json['invitation_code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      teamName: json['team_name'] as String?,
      invitedByUsername: json['invited_by_username'] as String?,
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'join_request_id': joinRequestId,
      'team_id': teamId,
      'user_id': userId,
      'invited_by_user_id': invitedByUserId,
      'invitation_code': invitationCode,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'team_name': teamName,
      'invited_by_username': invitedByUsername,
      'username': username,
    };
  }

  TeamJoinRequest copyWith({
    int? joinRequestId,
    int? teamId,
    int? userId,
    int? invitedByUserId,
    String? invitationCode,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? teamName,
    String? invitedByUsername,
    String? username,
  }) {
    return TeamJoinRequest(
      joinRequestId: joinRequestId ?? this.joinRequestId,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      invitationCode: invitationCode ?? this.invitationCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      teamName: teamName ?? this.teamName,
      invitedByUsername: invitedByUsername ?? this.invitedByUsername,
      username: username ?? this.username,
    );
  }
}


class CreateTeamInvitationRequest {
  final int teamId;
  final String invitationCode; // Player's invitation code
  final int? playerNumber;
  final bool isLibero;

  const CreateTeamInvitationRequest({
    required this.teamId,
    required this.invitationCode,
    this.playerNumber,
    this.isLibero = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'invitation_code': invitationCode,
      'player_number': playerNumber,
      'is_libero': isLibero,
    };
  }
}

class RespondToInvitationRequest {
  final bool accept;
  final int? playerNumber;
  final bool isLibero;

  const RespondToInvitationRequest({
    required this.accept,
    this.playerNumber,
    this.isLibero = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'accept': accept,
      'player_number': playerNumber,
      'is_libero': isLibero,
    };
  }
}
