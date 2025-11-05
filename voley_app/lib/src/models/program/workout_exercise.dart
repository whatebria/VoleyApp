import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/intensity.dart'; // Importa el nuevo modelo

/// Modelo para un ejercicio prescrito dentro de una TrainingSession.
@immutable
class WorkoutExercise {
  final String exerciseId;
  final String name;
  final int sets;

  // --- CAMBIOS: 'reps' e 'intensity' actualizados ---
  final int repsMin;
  final int repsMax;
  final Intensity prescription;
  // final String reps; // (Obsoleto)
  // final String intensity; // (Obsoleto)
  // --- FIN DE CAMBIOS ---

  const WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    // --- CAMBIOS ---
    required this.repsMin,
    required this.repsMax,
    required this.prescription,
    // required this.reps,
    // required this.intensity,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    // Lógica de migración/compatibilidad
    final String oldReps = json['reps'] as String? ?? '0';
    int repsMin = 0;
    int repsMax = 0;

    if (oldReps.contains('-')) {
      final parts = oldReps.split('-');
      repsMin = int.tryParse(parts.first.trim()) ?? 0;
      repsMax = int.tryParse(parts.last.trim()) ?? 0;
    } else {
      repsMin = int.tryParse(oldReps.trim()) ?? 0;
      repsMax = repsMin;
    }

    return WorkoutExercise(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sets: json['sets'] as int? ?? 0,
      
      // --- CAMBIOS ---
      repsMin: json['repsMin'] as int? ?? repsMin, // Lee nuevo o migra de 'reps'
      repsMax: json['repsMax'] as int? ?? repsMax, // Lee nuevo o migra de 'reps'
      
      // Parsea el objeto Intensity.
      // Si 'prescription' no existe, intenta migrar de 'intensity'
      prescription: json['prescription'] != null
          ? Intensity.fromJson(json['prescription'] as Map<String, dynamic>)
          : migrateIntensity(json['intensity'] as String?),
      // --- FIN DE CAMBIOS ---
    );
  }
  
  /// Lógica de migración para el campo 'intensity' (String)
  static Intensity migrateIntensity(String? oldIntensity) {
    if (oldIntensity == null || oldIntensity.isEmpty) {
      return const Intensity(type: IntensityType.open, label: 'N/A');
    }
    
    final lower = oldIntensity.toLowerCase();
    
    if (lower.contains('rpe')) {
      final numberPart = lower.replaceAll(RegExp(r'[^0-9.]'), '');
      return Intensity(
        type: IntensityType.rpe,
        value: double.tryParse(numberPart) ?? 0
      );
    }
    
    if (lower.contains('%')) {
      final numberPart = lower.replaceAll(RegExp(r'[^0-9.]'), '');
      return Intensity(
        type: IntensityType.percent_1rm,
        value: (double.tryParse(numberPart) ?? 0) / 100.0 // 80 -> 0.8
      );
    }
    
    if (lower.contains('kg') || lower.contains('lbs')) {
      final numberPart = lower.replaceAll(RegExp(r'[^0-9.]'), '');
      return Intensity(
        type: IntensityType.fixed_weight,
        value: double.tryParse(numberPart) ?? 0
      );
    }

    // Si no se reconoce, se guarda como etiqueta abierta
    return Intensity(type: IntensityType.open, label: oldIntensity);
  }


  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': sets,
    // --- CAMBIOS ---
    'repsMin': repsMin,
    'repsMax': repsMax,
    'prescription': prescription.toJson(),
    // --- FIN DE CAMBIOS ---
  };

  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    int? sets,
    // --- CAMBIOS ---
    int? repsMin,
    int? repsMax,
    Intensity? prescription,
    // --- FIN DE CAMBIOS ---
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      // --- CAMBIOS ---
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      prescription: prescription ?? this.prescription,
      // --- FIN DE CAMBIOS ---
    );
  }

  // --- Opcional: Métodos de igualdad ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is WorkoutExercise &&
      other.exerciseId == exerciseId &&
      other.name == name &&
      other.sets == sets &&
      other.repsMin == repsMin &&
      other.repsMax == repsMax &&
      other.prescription == prescription;
  }

  @override
  int get hashCode => 
    exerciseId.hashCode ^
    name.hashCode ^
    sets.hashCode ^
    repsMin.hashCode ^
    repsMax.hashCode ^
    prescription.hashCode;
}