import 'package:voley_app/src/models/bd/exercise.dart';

class TrainingSession {
  final String day;
  final String objective;
  final double load;
  final List<Exercise> exercises;

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
        day: json['day'],
        objective: json['objective'],
        load: (json['load'] as num).toDouble(),
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}