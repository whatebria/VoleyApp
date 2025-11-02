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

  // Constructor fromJson (seguro contra nulos)
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sets: json['sets'] as int? ?? 0,
      reps: json['reps'] as String? ?? '',
      intensity: json['intensity'] as String? ?? '',
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