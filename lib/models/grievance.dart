class Grievance {
  final String id;
  final String uid;
  final String category;
  final String subject;
  final String description;
  final String status;
  final DateTime createdAt;

  Grievance({
    required this.id,
    required this.uid,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      id: json['id'] as String,
      uid: json['uid'] as String,
      category: json['category'] as String,
      subject: json['subject'] as String? ?? 'No subject',
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

