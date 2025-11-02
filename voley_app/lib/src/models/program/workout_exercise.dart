// lib/src/models/program/workout_exercise.dart

class WorkoutExercise {
  final String exerciseId;
  final String name;
  final int sets;
  final String reps;
  final String intensity;

  WorkoutExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.intensity,
  });

  // Constructor fromJson
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? '',
      intensity: json['intensity'] ?? '',
    );
  }

  // Método toJson
  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': sets,
    'reps': reps,
    'intensity': intensity,
  };
}