import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:collection/collection.dart'; // Para ListEquality

/// Almacena el registro de todas las series completadas para un ejercicio
/// durante una sesión.
@immutable
class LoggedExercise {
  /// El ID del tipo de ejercicio (ej. "squat")
  final String exerciseId;

  /// La lista de series que el usuario SÍ hizo
  final List<SetLog> sets;

  const LoggedExercise({
    required this.exerciseId,
    this.sets = const [],
  });

  /// Serializa la instancia a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  /// Crea una instancia desde un mapa JSON.
  static LoggedExercise fromJson(Map<String, dynamic> json) => LoggedExercise(
        exerciseId: json['exerciseId'] as String? ?? '',
        sets: (json['sets'] as List<dynamic>? ?? [])
            .map((s) => SetLog.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  /// Crea una copia de la instancia con campos actualizados.
  LoggedExercise copyWith({
    String? exerciseId,
    List<SetLog>? sets,
  }) {
    return LoggedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
    );
  }

  @override
  String toString() => 'LoggedExercise(exerciseId: $exerciseId, sets: $sets)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
  
    return other is LoggedExercise &&
      other.exerciseId == exerciseId &&
      listEquals(other.sets, sets);
  }

  @override
  int get hashCode => exerciseId.hashCode ^ const DeepCollectionEquality().hash(sets);
}