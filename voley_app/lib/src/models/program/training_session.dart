// lib/src/models/program/training_session.dart
import 'package:voley_app/src/models/program/workout_exercise.dart'; 

class TrainingSession {
  final String day;
  final String objective;
  final double load;
  final List<WorkoutExercise> exercises;

  TrainingSession({
    required this.day,
    required this.objective,
    required this.load,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'objective': objective,
    'load': load,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
    day: json['day'] as String? ?? '',
    objective: json['objective'] as String? ?? '',
    load: (json['load'] as num?)?.toDouble() ?? 0.0,
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
  TrainingSession copyWith({
    String? day,
    String? objective,
    double? load,
    List<WorkoutExercise>? exercises,
  }) {
    return TrainingSession(
      day: day ?? this.day,
      objective: objective ?? this.objective,
      load: load ?? this.load,
      exercises: exercises ?? this.exercises,
    );
  }
}