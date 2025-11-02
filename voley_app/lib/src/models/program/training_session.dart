// lib/src/models/program/training_session.dart

import 'package:voley_app/src/models/program/workout_exercise.dart';

class TrainingSession {
  final String day;
  final String objective;
  final double load;
  final List<WorkoutExercise> exercises; // <-- DEBE SER WorkoutExercise

  TrainingSession({
    required this.day,
    required this.objective,
    required this.load,
    required this.exercises, // <-- DEBE SER WorkoutExercise
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'objective': objective,
    'load': load,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  // --- ESTE MÉTODO DEBE VERSE ASÍ ---
  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
    day: json['day'] as String? ?? '', // Seguro contra nulos
    objective: json['objective'] as String? ?? '', // Seguro contra nulos
    load: (json['load'] as num?)?.toDouble() ?? 0.0, // Seguro contra nulos
    
    // Ahora mapea a WorkoutExercise.fromJson
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}