// lib/src/models/program/session_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Representa una sola serie completada
class SetLog {
  final int setNumber;
  final double weight;
  final int reps;

  SetLog({required this.setNumber, required this.weight, required this.reps});
  
  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weight': weight,
    'reps': reps,
  };
}

// Representa el registro completo de la sesión
class SessionLog {
  final String id;
  final String profileId;
  final String sessionId; // ID de la TrainingSession original
  final DateTime completedAt;
  // Mapa: "exerciseId" -> Lista de series completadas
  final Map<String, List<SetLog>> exercises; 

  SessionLog({
    required this.id,
    required this.profileId,
    required this.sessionId,
    required this.completedAt,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'sessionId': sessionId,
    'completedAt': Timestamp.fromDate(completedAt), // Convierte a Timestamp
    'exercises': exercises.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    ),
  };
}