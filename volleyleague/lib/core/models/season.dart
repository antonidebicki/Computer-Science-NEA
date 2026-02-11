class Season {
  final int seasonId;
  final int leagueId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int matchesPerWeekPerTeam;
  final int weeksBetweenMatches;
  final bool doubleRoundRobin;
  final List<int> allowedWeekdays;
  final bool isArchived;

  const Season({
    required this.seasonId,
    required this.leagueId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.matchesPerWeekPerTeam = 1,
    this.weeksBetweenMatches = 1,
    this.doubleRoundRobin = false,
    this.allowedWeekdays = const [1, 3, 5],
    this.isArchived = false,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    final allowedWeekdaysJson = json['allowed_weekdays'] as List<dynamic>?;
    return Season(
      seasonId: json['season_id'] as int,
      leagueId: json['league_id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      matchesPerWeekPerTeam:
          json['matches_per_week_per_team'] as int? ?? 1,
      weeksBetweenMatches: json['weeks_between_matches'] as int? ?? 1,
      doubleRoundRobin: json['double_round_robin'] as bool? ?? false,
      allowedWeekdays: allowedWeekdaysJson
              ?.map((value) => value as int)
              .toList() ??
          const [1, 3, 5],
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
      'matches_per_week_per_team': matchesPerWeekPerTeam,
      'weeks_between_matches': weeksBetweenMatches,
      'double_round_robin': doubleRoundRobin,
      'allowed_weekdays': allowedWeekdays,
      'is_archived': isArchived,
    };
  }


  Season copyWith({
    int? seasonId,
    int? leagueId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    int? matchesPerWeekPerTeam,
    int? weeksBetweenMatches,
    bool? doubleRoundRobin,
    List<int>? allowedWeekdays,
    bool? isArchived,
  }) {
    return Season(
      seasonId: seasonId ?? this.seasonId,
      leagueId: leagueId ?? this.leagueId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      matchesPerWeekPerTeam:
          matchesPerWeekPerTeam ?? this.matchesPerWeekPerTeam,
      weeksBetweenMatches: weeksBetweenMatches ?? this.weeksBetweenMatches,
      doubleRoundRobin: doubleRoundRobin ?? this.doubleRoundRobin,
      allowedWeekdays: allowedWeekdays ?? this.allowedWeekdays,
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
    return 'Season{seasonId: $seasonId, leagueId: $leagueId, name: $name, startDate: $startDate, endDate: $endDate, matchesPerWeekPerTeam: $matchesPerWeekPerTeam, weeksBetweenMatches: $weeksBetweenMatches, doubleRoundRobin: $doubleRoundRobin, allowedWeekdays: $allowedWeekdays, isArchived: $isArchived}';
  }
}
