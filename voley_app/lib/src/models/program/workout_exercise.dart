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

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sets: json['sets'] as int? ?? 0,
      reps: json['reps'] as String? ?? '',
      intensity: json['intensity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'sets': sets,
    'reps': reps,
    'intensity': intensity,
  };
  WorkoutExercise copyWith({
    String? exerciseId,
    String? name,
    int? sets,
    String? reps,
    String? intensity,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      intensity: intensity ?? this.intensity,
    );
  }
}
