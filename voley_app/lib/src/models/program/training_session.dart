// lib/src/models/program/training_session.dart
import 'package:voley_app/src/models/program/workout_exercise.dart'; // <-- Importa el nuevo modelo

class TrainingSession {
  final String day;
  final String objective;
  final double load;
  final List<WorkoutExercise> exercises; // <-- CAMBIADO de List<Exercise>

  TrainingSession({
    required this.day,
    required this.objective,
    required this.load,
    required this.exercises, // <-- CAMBIADO
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'objective': objective,
    'load': load,
    'exercises': exercises.map((e) => e.toJson()).toList(), // <-- Esto ya es correcto
  };

  // --- MÉTODO fromJson CORREGIDO ---
  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
    day: json['day'] ?? '',
    objective: json['objective'] ?? '',
    load: (json['load'] as num?)?.toDouble() ?? 0.0, // Más seguro
    // Ahora mapea a WorkoutExercise.fromJson
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}