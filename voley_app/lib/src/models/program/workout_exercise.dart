import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/intensity.dart';

@immutable
class RepsRange {
  final int min;
  final int max;
  const RepsRange(this.min, this.max);

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
  static RepsRange fromJson(Map<String, dynamic> j) =>
      RepsRange((j['min'] as num?)?.toInt() ?? 0, (j['max'] as num?)?.toInt() ?? 0);

  @override
  String toString() => '$min-$max';

  /// Permite "8" o "8-10".
  static RepsRange parseLoose(String input) {
    final s = input.trim();
    if (s.contains('-')) {
      final p = s.split('-');
      final a = int.tryParse(p.first.trim()) ?? 0;
      final b = int.tryParse(p.last.trim()) ?? a;
      return RepsRange(a, b);
    }
    final v = int.tryParse(s) ?? 0;
    return RepsRange(v, v);
  }
}

/// Ejercicio prescrito dentro de una sesión de entrenamiento.
@immutable
class WorkoutExercise {
  final String exerciseId;
  final String name;
  final int sets;
  final RepsRange reps;
  final Intensity prescription;

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.prescription,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': sets,
    'reps': reps.toJson(),
    'prescription': prescription.toJson(),
  };

  static WorkoutExercise fromJson(Map<String, dynamic> json) => WorkoutExercise(
    exerciseId: json['exerciseId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    sets: (json['sets'] as num?)?.toInt() ?? 3,
    reps: (json['reps'] is Map)
      ? RepsRange.fromJson((json['reps'] as Map).cast<String, dynamic>())
      : const RepsRange(0, 0),
    prescription: (json['prescription'] is Map)
      ? Intensity.fromJson((json['prescription'] as Map).cast<String, dynamic>())
      : const Intensity(type: IntensityType.open, value: 0),
  );

  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    int? sets,
    RepsRange? reps,
    Intensity? prescription,
  }) => WorkoutExercise(
    exerciseId: exerciseId ?? this.exerciseId,
    name: name ?? this.name,
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    prescription: prescription ?? this.prescription,
  );

  @override
  String toString() => 'WorkoutExercise($name • ${reps.min}-${reps.max} x$sets, ${prescription.type.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExercise &&
        other.exerciseId == exerciseId &&
        other.name == name &&
        other.sets == sets &&
        other.reps == reps &&
        other.prescription == prescription;

  @override
  int get hashCode => exerciseId.hashCode ^ name.hashCode ^ sets.hashCode ^ reps.hashCode ^ prescription.hashCode;
}
