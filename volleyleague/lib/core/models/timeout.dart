/// Timeout model representing a timeout called during a set
class Timeout {
  final int timeoutId;
  final int setId;
  final int teamId;
  final String? scoreAtTimeout;
  final DateTime timestamp;

  const Timeout({
    required this.timeoutId,
    required this.setId,
    required this.teamId,
    this.scoreAtTimeout,
    required this.timestamp,
  });

  /// Create a Timeout from a JSON map
  factory Timeout.fromJson(Map<String, dynamic> json) {
    return Timeout(
      timeoutId: json['timeout_id'] as int,
      setId: json['set_id'] as int,
      teamId: json['team_id'] as int,
      scoreAtTimeout: json['score_at_timeout'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert Timeout to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'timeout_id': timeoutId,
      'set_id': setId,
      'team_id': teamId,
      'score_at_timeout': scoreAtTimeout,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy of Timeout with some fields replaced
  Timeout copyWith({
    int? timeoutId,
    int? setId,
    int? teamId,
    String? scoreAtTimeout,
    DateTime? timestamp,
  }) {
    return Timeout(
      timeoutId: timeoutId ?? this.timeoutId,
      setId: setId ?? this.setId,
      teamId: teamId ?? this.teamId,
      scoreAtTimeout: scoreAtTimeout ?? this.scoreAtTimeout,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Timeout &&
          runtimeType == other.runtimeType &&
          timeoutId == other.timeoutId;

  @override
  int get hashCode => timeoutId.hashCode;

  @override
  String toString() {
    return 'Timeout{timeoutId: $timeoutId, setId: $setId, teamId: $teamId, scoreAtTimeout: $scoreAtTimeout, timestamp: $timestamp}';
  }
}
