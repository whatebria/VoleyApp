import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';

class Program {
  final String id;
  final String source;
  final DateTime startDate;
  final DateTime endDate;
  final List<Mesocycle> mesocycles;

  Program({
    required this.id,
    required this.source,
    required this.startDate,
    required this.endDate,
    required this.mesocycles,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'mesocycles': mesocycles.map((m) => m.toJson()).toList(),
      };

  static Program fromJson(Map<String, dynamic> json) => Program(
        id: json['id'],
        source: json['source'],
        startDate: (json['startDate'] as Timestamp).toDate(),
        endDate: (json['endDate'] as Timestamp).toDate(),
        mesocycles: (json['mesocycles'] as List<dynamic>? ?? [])
            .map((m) => Mesocycle.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}