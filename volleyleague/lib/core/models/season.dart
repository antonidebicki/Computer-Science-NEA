class Season {
  final int seasonId;
  final int leagueId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isArchived;

  const Season({
    required this.seasonId,
    required this.leagueId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isArchived = false,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonId: json['season_id'] as int,
      leagueId: json['league_id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season_id': seasonId,
      'league_id': leagueId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'end_date': endDate.toIso8601String().split('T')[0], // Date only
      'is_archived': isArchived,
    };
  }


  Season copyWith({
    int? seasonId,
    int? leagueId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isArchived,
  }) {
    return Season(
      seasonId: seasonId ?? this.seasonId,
      leagueId: leagueId ?? this.leagueId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Season &&
          runtimeType == other.runtimeType &&
          seasonId == other.seasonId;

  @override
  int get hashCode => seasonId.hashCode;

  @override
  String toString() {
    return 'Season{seasonId: $seasonId, leagueId: $leagueId, name: $name, startDate: $startDate, endDate: $endDate, isArchived: $isArchived}';
  }
}
