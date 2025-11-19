// Compact model for trains used across booking and admin views
class Train {
  final String number;
  final String name;
  final String source;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String status;
  final double ticketAmount;
  final DateTime? lastUpdated;

  Train({
    required this.number,
    required this.name,
    required this.source,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.status,
    required this.ticketAmount,
    this.lastUpdated,
  });

  factory Train.fromJson(Map<String, dynamic> json) {
    return Train(
      number: json['number'] as String,
      name: json['name'] as String,
      source: json['source'] as String,
      destination: json['destination'] as String,
      departureTime: json['departureTime'] as String,
      arrivalTime: json['arrivalTime'] as String,
      status: json['status'] as String,
      ticketAmount: (json['ticketAmount'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }
}

