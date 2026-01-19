class Team {
  final int teamId;
  final String name;
  final int createdByUserId;
  final String? logoUrl;
  final DateTime createdAt;

  const Team({
    required this.teamId,
    required this.name,
    required this.createdByUserId,
    this.logoUrl,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamId: json['team_id'] as int,
      name: json['name'] as String,
      createdByUserId: json['created_by_user_id'] as int,
      logoUrl: json['logo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'name': name,
      'created_by_user_id': createdByUserId,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Team copyWith({
    int? teamId,
    String? name,
    int? createdByUserId,
    String? logoUrl,
    DateTime? createdAt,
  }) {
    return Team(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && teamId == other.teamId;

  @override
  int get hashCode => teamId.hashCode;

  @override
  String toString() {
    return 'Team{teamId: $teamId, name: $name, createdByUserId: $createdByUserId, logoUrl: $logoUrl}';
  }
}
