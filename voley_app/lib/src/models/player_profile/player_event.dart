import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerEvent {
  final String type; // league, cup, playoff, national_team, travel
  final DateTime date;
  final String? description;

  const PlayerEvent({
    required this.type,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'date': Timestamp.fromDate(date),
        'description': description,
      };

  static PlayerEvent fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return PlayerEvent(
      type: json['type'] as String? ?? 'league',
      date: parsedDate,
      description: json['description'] as String?,
    );
  }

  PlayerEvent copyWith({
    String? type,
    DateTime? date,
    String? description,
  }) {
    return PlayerEvent(
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}
