class PnrPassenger {
  final String name;
  final int age;
  final String gender;
  final String coach;
  final int seat;
  final String berth;
  final String bookingStatus;
  final String currentStatus;

  PnrPassenger({
    required this.name,
    required this.age,
    required this.gender,
    required this.coach,
    required this.seat,
    required this.berth,
    required this.bookingStatus,
    required this.currentStatus,
  });

  factory PnrPassenger.fromJson(Map<String, dynamic> json) {
    return PnrPassenger(
      name: json['name'] as String,
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String,
      coach: json['coach'] as String,
      seat: (json['seat'] as num).toInt(),
      berth: json['berth'] as String,
      bookingStatus: json['bookingStatus'] as String,
      currentStatus: json['currentStatus'] as String,
    );
  }
}

class PnrRecord {
  final String pnr;
  final String trainNumber;
  final String trainName;
  final String journeyDate;
  final String from;
  final String to;
  final List<PnrPassenger> passengers;
  final String trainStatus;
  final String chartStatus;
  final String departureTime;
  final String arrivalTime;
  final String platform;
  final String coachPosition;
  final String bookingClass;
  final String fare;
  final int? quantity;
  final String? ticketPrice;
  final String bookingDate;
  final String boardingStation;
  final String destinationStation;
  final String journeyClass;
  final String quota;
  final String currentStatus;
  final String lastUpdated;
  final String? paymentMethod;
  final String? cardNumber;
  final String? transactionId;
  final String? paymentStatus;
  final String? paymentDate;

  PnrRecord({
    required this.pnr,
    required this.trainNumber,
    required this.trainName,
    required this.journeyDate,
    required this.from,
    required this.to,
    required this.passengers,
    required this.trainStatus,
    required this.chartStatus,
    required this.departureTime,
    required this.arrivalTime,
    required this.platform,
    required this.coachPosition,
    required this.bookingClass,
    required this.fare,
    this.quantity,
    this.ticketPrice,
    required this.bookingDate,
    required this.boardingStation,
    required this.destinationStation,
    required this.journeyClass,
    required this.quota,
    required this.currentStatus,
    required this.lastUpdated,
    this.paymentMethod,
    this.cardNumber,
    this.transactionId,
    this.paymentStatus,
    this.paymentDate,
  });

  factory PnrRecord.fromJson(Map<String, dynamic> json) {
    return PnrRecord(
      pnr: json['pnr'] as String,
      trainNumber: json['trainNumber'] as String,
      trainName: json['trainName'] as String,
      journeyDate: json['journeyDate'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      passengers: (json['passengers'] as List<dynamic>)
          .map((p) => PnrPassenger.fromJson(p as Map<String, dynamic>))
          .toList(),
      trainStatus: json['trainStatus'] as String? ?? 'On Time',
      chartStatus: json['chartStatus'] as String? ?? 'Chart Not Prepared',
      departureTime: json['departureTime'] as String? ?? 'N/A',
      arrivalTime: json['arrivalTime'] as String? ?? 'N/A',
      platform: json['platform'] as String? ?? 'TBA',
      coachPosition: json['coachPosition'] as String? ?? 'N/A',
      bookingClass: json['bookingClass'] as String? ?? 'SL',
      fare: json['fare'] as String? ?? '0',
      quantity: json['quantity'] as int?,
      ticketPrice: json['ticketPrice'] as String?,
      bookingDate: json['bookingDate'] as String? ?? 'N/A',
      boardingStation: json['boardingStation'] as String? ?? 'N/A',
      destinationStation: json['destinationStation'] as String? ?? 'N/A',
      journeyClass: json['journeyClass'] as String? ?? 'SL',
      quota: json['quota'] as String? ?? 'GN',
      currentStatus: json['currentStatus'] as String? ?? 'Confirmed',
      lastUpdated: json['lastUpdated'] as String? ?? DateTime.now().toIso8601String(),
      paymentMethod: json['paymentMethod'] as String?,
      cardNumber: json['cardNumber'] as String?,
      transactionId: json['transactionId'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      paymentDate: json['paymentDate'] as String?,
    );
  }
}

