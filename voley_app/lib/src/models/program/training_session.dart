import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:uuid/uuid.dart';

class TrainingSession {
  final String id;
  final String day;
  final String objective;
  final double load;
  final List<WorkoutExercise> exercises;

  TrainingSession({
    required this.id,
    required this.day,
    required this.objective,
    required this.load,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'objective': objective,
        'load': load,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
        id: json['id'] as String? ?? const Uuid().v4(),
        day: json['day'] as String? ?? 'Día 1',
        objective: json['objective'] as String? ?? '',
        load: (json['load'] as num?)?.toDouble() ?? 0.0,
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // --- AÑADIDO: Método copyWith ---
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
