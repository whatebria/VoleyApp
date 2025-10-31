// lib/src/models/program.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Program {
  final String id;
  final String name;
  final String description;
  final String focus; // e.g. fuerza, potencia, técnica
  final String phase; // pretemporada, temporada, recuperación...
  final List<String> recommendedTags;
  final List<String> testIds;
  final List<String> exerciseIds;
  final DateTime? startDate;
  final DateTime? endDate;

  Program({
    required this.id,
    required this.name,
    required this.description,
    required this.focus,
    required this.phase,
    required this.recommendedTags,
    required this.testIds,
    required this.exerciseIds,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'focus': focus,
      'phase': phase,
      'recommendedTags': recommendedTags,
      'testIds': testIds,
      'exerciseIds': exerciseIds,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  factory Program.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Program(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      focus: data['focus'] ?? '',
      phase: data['phase'] ?? '',
      recommendedTags: List<String>.from(data['recommendedTags'] ?? []),
      testIds: List<String>.from(data['testIds'] ?? []),
      exerciseIds: List<String>.from(data['exerciseIds'] ?? []),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }
}
