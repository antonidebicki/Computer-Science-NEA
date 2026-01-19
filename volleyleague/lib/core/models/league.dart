class League {
  final int leagueId;
  final String name;
  final int adminUserId;
  final String? description;
  final String? rules;
  final DateTime createdAt;

  const League({
    required this.leagueId,
    required this.name,
    required this.adminUserId,
    this.description,
    this.rules,
    required this.createdAt,
  });

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      leagueId: json['league_id'] as int,
      name: json['name'] as String,
      adminUserId: json['admin_user_id'] as int,
      description: json['description'] as String?,
      rules: json['rules'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'league_id': leagueId,
      'name': name,
      'admin_user_id': adminUserId,
      'description': description,
      'rules': rules,
      'created_at': createdAt.toIso8601String(),
    };
  }

  League copyWith({
    int? leagueId,
    String? name,
    int? adminUserId,
    String? description,
    String? rules,
    DateTime? createdAt,
  }) {
    return League(
      leagueId: leagueId ?? this.leagueId,
      name: name ?? this.name,
      adminUserId: adminUserId ?? this.adminUserId,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is League &&
          runtimeType == other.runtimeType &&
          leagueId == other.leagueId;

  @override
  int get hashCode => leagueId.hashCode;

  @override
  String toString() {
    return 'League{leagueId: $leagueId, name: $name, adminUserId: $adminUserId}';
  }
}
