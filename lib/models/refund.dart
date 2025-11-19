class RefundRequest {
  final String id;
  final String bookingId;
  final String uid;
  final double amount;
  final String reason;
  final String status;
  final DateTime requestedAt;
  final DateTime updatedAt;

  RefundRequest({
    required this.id,
    required this.bookingId,
    required this.uid,
    required this.amount,
    required this.reason,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      uid: json['uid'] as String,
      amount: (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

