import 'enums.dart';

/// Payment model representing payments between entities in the system
class Payment {
  final int paymentId;
  final int? requesterLeagueId;
  final int? requesterTeamId;
  final int? payerTeamId;
  final int? payerUserId;
  final double amount;
  final String description;
  final DateTime? dueDate;
  final PaymentStatus status;
  final DateTime createdAt;

  const Payment({
    required this.paymentId,
    this.requesterLeagueId,
    this.requesterTeamId,
    this.payerTeamId,
    this.payerUserId,
    required this.amount,
    required this.description,
    this.dueDate,
    this.status = PaymentStatus.unpaid,
    required this.createdAt,
  });

  /// Check if payment is overdue
  bool get isOverdue {
    if (status == PaymentStatus.paid) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Create a Payment from a JSON map
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['payment_id'] as int,
      requesterLeagueId: json['requester_league_id'] as int?,
      requesterTeamId: json['requester_team_id'] as int?,
      payerTeamId: json['payer_team_id'] as int?,
      payerUserId: json['payer_user_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: json['status'] != null
          ? PaymentStatus.fromString(json['status'] as String)
          : PaymentStatus.unpaid,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert Payment to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'requester_league_id': requesterLeagueId,
      'requester_team_id': requesterTeamId,
      'payer_team_id': payerTeamId,
      'payer_user_id': payerUserId,
      'amount': amount,
      'description': description,
      'due_date': dueDate?.toIso8601String().split('T')[0], // Date only
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of Payment with some fields replaced
  Payment copyWith({
    int? paymentId,
    int? requesterLeagueId,
    int? requesterTeamId,
    int? payerTeamId,
    int? payerUserId,
    double? amount,
    String? description,
    DateTime? dueDate,
    PaymentStatus? status,
    DateTime? createdAt,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      requesterLeagueId: requesterLeagueId ?? this.requesterLeagueId,
      requesterTeamId: requesterTeamId ?? this.requesterTeamId,
      payerTeamId: payerTeamId ?? this.payerTeamId,
      payerUserId: payerUserId ?? this.payerUserId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          paymentId == other.paymentId;

  @override
  int get hashCode => paymentId.hashCode;

  @override
  String toString() {
    return 'Payment{paymentId: $paymentId, amount: $amount, description: $description, status: $status, dueDate: $dueDate}';
  }
}
