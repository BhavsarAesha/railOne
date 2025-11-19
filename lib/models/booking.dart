// Represents a ticket booking captured for a user and mirrored for admin
class Booking {
  final String id;
  final String trainNumber;
  final String trainName;
  final String from;
  final String to;
  final String departureTime;
  final String arrivalTime;
  final DateTime createdAt;
  final double amount;
  final int quantity;
  final String status;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? pnr;
  final DateTime? cancelledAt;
  final String? journeyDate; // yyyy-MM-dd derived from departureTime
  final List<int>? seats; // selected seat numbers
  final List<String>? seatCodes; // e.g., CNF/B14/27/UPPER
  final List<Map<String, dynamic>>? passengers; // [{name, age, gender, mobile}]
  final String? selectedCoach; // e.g., B14

  Booking({
    required this.id,
    required this.trainNumber,
    required this.trainName,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    required this.createdAt,
    required this.amount,
    required this.quantity,
    this.status = 'confirmed',
    this.userId,
    this.userName,
    this.userEmail,
    this.pnr,
    this.cancelledAt,
    this.journeyDate,
    this.seats,
    this.seatCodes,
    this.passengers,
    this.selectedCoach,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainNumber': trainNumber,
        'trainName': trainName,
        'from': from,
        'to': to,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'createdAt': createdAt.toIso8601String(),
        'amount': amount,
        'quantity': quantity,
        'status': status,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'pnr': pnr,
        'cancelledAt': cancelledAt?.toIso8601String(),
        'journeyDate': journeyDate,
        'seats': seats,
        'seatCodes': seatCodes,
        'passengers': passengers,
        'selectedCoach': selectedCoach,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        trainNumber: json['trainNumber'] as String,
        trainName: json['trainName'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        departureTime: json['departureTime'] as String,
        arrivalTime: json['arrivalTime'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        amount: (json['amount'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
        status: json['status'] as String? ?? 'confirmed',
        userId: json['userId'] as String?,
        userName: json['userName'] as String?,
        userEmail: json['userEmail'] as String?,
        pnr: json['pnr'] as String?,
        cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'] as String) : null,
        journeyDate: json['journeyDate'] as String?,
        seats: (json['seats'] as List?)?.map((e) => (e as num).toInt()).toList(),
        seatCodes: (json['seatCodes'] as List?)?.map((e) => e.toString()).toList(),
        passengers: (json['passengers'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        selectedCoach: json['selectedCoach'] as String?,
      );
}

