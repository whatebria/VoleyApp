// lib/src/models/training_program.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingProgram {
  final String id;
  final String athleteId;
  final String name;
  final String focus; // Ej: "Mejorar salto vertical"
  final String intensity; // baja / media / alta
  final int durationWeeks;
  final int weeklyFrequency;
  final DateTime createdAt;
  final List<Map<String, dynamic>> exercises; // lista de ejercicios completos (snapshot-like)
  final List<String> recommendations;

  TrainingProgram({
    required this.id,
    required this.athleteId,
    required this.name,
    required this.focus,
    required this.intensity,
    required this.durationWeeks,
    required this.weeklyFrequency,
    required this.createdAt,
    required this.exercises,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'athleteId': athleteId,
      'name': name,
      'focus': focus,
      'intensity': intensity,
      'durationWeeks': durationWeeks,
      'weeklyFrequency': weeklyFrequency,
      'createdAt': createdAt.toIso8601String(),
      'exercises': exercises,
      'recommendations': recommendations,
    };
  }

  factory TrainingProgram.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TrainingProgram(
      id: doc.id,
      athleteId: data['athleteId'] ?? '',
      name: data['name'] ?? '',
      focus: data['focus'] ?? '',
      intensity: data['intensity'] ?? 'media',
      durationWeeks: data['durationWeeks'] ?? 4,
      weeklyFrequency: data['weeklyFrequency'] ?? 4,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      exercises: List<Map<String, dynamic>>.from(data['exercises'] ?? []),
      recommendations: List<String>.from(data['recommendations'] ?? []),
    );
  }
}
