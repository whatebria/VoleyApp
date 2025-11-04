import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:uuid/uuid.dart';

class TrainingSession {
  final String id;
  final String day;
  final double load;
  final List<WorkoutExercise> exercises;

  TrainingSession({
    required this.id,
    required this.day,
    required this.load,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'load': load,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
        id: json['id'] as String? ?? const Uuid().v4(),
        day: json['day'] as String? ?? 'Día 1',
        load: (json['load'] as num?)?.toDouble() ?? 0.0,
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // --- AÑADIDO: Método copyWith ---
  TrainingSession copyWith({
    String? id,
    String? day,
    double? load,
    List<WorkoutExercise>? exercises,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      day: day ?? this.day,
      load: load ?? this.load,
      exercises: exercises ?? this.exercises,
    );
  }
}
