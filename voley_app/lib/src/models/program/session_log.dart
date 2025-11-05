import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/logged_excercise.dart';
import 'package:collection/collection.dart'; // Para ListEquality

/// Almacena el resultado de una única serie completada por el atleta.
@immutable
class SetLog {
  /// El número de la serie (ej. 1, 2, 3...)
  final int setNumber;

  /// El número de repeticiones que el atleta SÍ hizo.
  final int reps;

  /// El peso que el atleta SÍ levantó (en kg/lbs).
  final double weight;
  
  /// El RPE que el atleta SÍ sintió (opcional).
  final double? rpe;

  const SetLog({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.rpe,
  });

  /// Serializa la instancia a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
        'rpe': rpe,
      };

  /// Crea una instancia desde un mapa JSON.
  static SetLog fromJson(Map<String, dynamic> json) => SetLog(
        setNumber: json['setNumber'] as int? ?? 1,
        reps: json['reps'] as int? ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
        rpe: (json['rpe'] as num?)?.toDouble(),
      );

  /// Crea una copia de la instancia con campos actualizados.
  SetLog copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    double? rpe,
  }) {
    return SetLog(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      rpe: rpe ?? this.rpe,
    );
  }

  @override
  String toString() {
    return 'SetLog(setNumber: $setNumber, reps: $reps, weight: $weight, rpe: $rpe)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is SetLog &&
      other.setNumber == setNumber &&
      other.reps == reps &&
      other.weight == weight &&
      other.rpe == rpe;
  }

  @override
  int get hashCode => setNumber.hashCode ^ reps.hashCode ^ weight.hashCode ^ rpe.hashCode;
}

// Representa el registro completo de la sesión
@immutable // --- AÑADIDO ---
class SessionLog {
  final String id;
  final String profileId;
  final String sessionId; // ID de la TrainingSession original
  final DateTime completedAt;
  // --- CAMBIO: El tipo es List<LoggedExercise> ---
  final List<LoggedExercise> loggedExercises;
  
  // --- CAMPOS AÑADIDOS ---
  final int rpe; // Esfuerzo Percibido (Rating of Perceived Exertion)
  final String notes; // Notas del jugador

  const SessionLog({ // --- AÑADIDO const ---
    required this.id,
    required this.profileId,
    required this.sessionId,
    required this.completedAt,
    required this.loggedExercises,
    required this.rpe, // --- AÑADIDO ---
    required this.notes, // --- AÑADIDO ---
  });

  /// Convierte el objeto a un Mapa para guardar en Firestore
  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'sessionId': sessionId,
    'completedAt': Timestamp.fromDate(completedAt), // Convierte DateTime a Timestamp
    // --- CORRECCIÓN: Mapea la List<LoggedExercise> a JSON ---
    'loggedExercises': loggedExercises.map((e) => e.toJson()).toList(),
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
      // --- CORRECCIÓN: Parsea una List<dynamic> a List<LoggedExercise> ---
      loggedExercises: (json['loggedExercises'] as List<dynamic>? ?? [])
          .map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      rpe: json['rpe'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }

  // --- AÑADIDO: copyWith ---
  SessionLog copyWith({
    String? id,
    String? profileId,
    String? sessionId,
    DateTime? completedAt,
    List<LoggedExercise>? loggedExercises,
    int? rpe,
    String? notes,
  }) {
    return SessionLog(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      sessionId: sessionId ?? this.sessionId,
      completedAt: completedAt ?? this.completedAt,
      loggedExercises: loggedExercises ?? this.loggedExercises,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  // --- AÑADIDO: toString, ==, hashCode ---
  @override
  String toString() {
    return 'SessionLog(id: $id, profileId: $profileId, sessionId: $sessionId, completedAt: $completedAt, loggedExercises: $loggedExercises, rpe: $rpe, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return other is SessionLog &&
      other.id == id &&
      other.profileId == profileId &&
      other.sessionId == sessionId &&
      other.completedAt == completedAt &&
      listEquals(other.loggedExercises, loggedExercises) &&
      other.rpe == rpe &&
      other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      profileId.hashCode ^
      sessionId.hashCode ^
      completedAt.hashCode ^
      const DeepCollectionEquality().hash(loggedExercises) ^
      rpe.hashCode ^
      notes.hashCode;
  }
}