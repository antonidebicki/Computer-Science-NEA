class MatchReferee {
  final int matchId;
  final int userId;
  final String refereeRole;

  const MatchReferee({
    required this.matchId,
    required this.userId,
    required this.refereeRole,
  });

  factory MatchReferee.fromJson(Map<String, dynamic> json) {
    return MatchReferee(
      matchId: json['match_id'] as int,
      userId: json['user_id'] as int,
      refereeRole: json['referee_role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'user_id': userId,
      'referee_role': refereeRole,
    };
  }

  MatchReferee copyWith({
    int? matchId,
    int? userId,
    String? refereeRole,
  }) {
    return MatchReferee(
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      refereeRole: refereeRole ?? this.refereeRole,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchReferee &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(matchId, userId);

  @override
  String toString() {
    return 'MatchReferee{matchId: $matchId, userId: $userId, refereeRole: $refereeRole}';
  }
}
