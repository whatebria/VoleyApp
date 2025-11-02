// lib/src/models/program/training_session.dart
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:uuid/uuid.dart'; // Importa Uuid

class TrainingSession {
  final String id; // <-- 1. AÑADE UN ID
  final String day;
  final String objective;
  final double load;
  final List<WorkoutExercise> exercises;

  TrainingSession({
    String? id, // <-- 2. Hazlo opcional en el constructor
    required this.day,
    required this.objective,
    required this.load,
    required this.exercises,
  }) : id = id ?? const Uuid().v4(); // <-- 3. Asigna un ID si no se provee

  Map<String, dynamic> toJson() => {
    'id': id, // <-- 4. AÑADE AL toJson
    'day': day,
    'objective': objective,
    'load': load,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id'] as String? ?? const Uuid().v4(), // <-- 5. LEE DEL fromJson
    day: json['day'] as String? ?? '',
    objective: json['objective'] as String? ?? '',
    load: (json['load'] as num?)?.toDouble() ?? 0.0,
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  // --- 6. AÑADE un método copyWith ---
  // (Lo necesitarás para tu editor manual)
  TrainingSession copyWith({
    String? id,
    String? day,
    String? objective,
    double? load,
    List<WorkoutExercise>? exercises,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      day: day ?? this.day,
      objective: objective ?? this.objective,
      load: load ?? this.load,
      exercises: exercises ?? this.exercises,
    );
  }
}