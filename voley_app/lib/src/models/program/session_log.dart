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
  
  // Constructor fromJson para leer los datos
  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      setNumber: json['setNumber'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
    );
  }
}

// Representa el registro completo de la sesión
class SessionLog {
  final String id;
  final String profileId;
  final String sessionId; // ID de la TrainingSession original
  final DateTime completedAt;
  // Mapa: "exerciseId" -> Lista de series completadas
  final Map<String, List<SetLog>> exercises; 
  
  // --- CAMPOS AÑADIDOS ---
  final int rpe; // Esfuerzo Percibido (Rating of Perceived Exertion)
  final String notes; // Notas del jugador

  SessionLog({
    required this.id,
    required this.profileId,
    required this.sessionId,
    required this.completedAt,
    required this.exercises,
    required this.rpe, // --- AÑADIDO ---
    required this.notes, // --- AÑADIDO ---
  });

  /// Convierte el objeto a un Mapa para guardar en Firestore
  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'sessionId': sessionId,
    'completedAt': Timestamp.fromDate(completedAt), // Convierte DateTime a Timestamp
    'exercises': exercises.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    ),
    'rpe': rpe, // --- AÑADIDO ---
    'notes': notes, // --- AÑADIDO ---
  };
  
  /// (NUEVO) Crea un objeto SessionLog desde un Mapa de Firestore
  factory SessionLog.fromJson(Map<String, dynamic> json) {
    return SessionLog(
      id: json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      completedAt: (json['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Mapea el mapa de ejercicios
      exercises: (json['exercises'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? [])
              .map((e) => SetLog.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      rpe: json['rpe'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}