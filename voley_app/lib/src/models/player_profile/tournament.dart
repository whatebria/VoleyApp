import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final DateTime date;
  final String name;

  Tournament({required this.date, required this.name});

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'name': name,
      };

  static Tournament fromJson(Map<String, dynamic> json) => Tournament(
        date: (json['date'] is Timestamp) ? (json['date'] as Timestamp).toDate() : DateTime.parse(json['date']),
        name: json['name'] ?? '',
      );
}