import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';
import 'package:voley_app/utils/common/utils.dart';

@immutable
class TrainingSession {
  final String id;
  final DayOfWeek day;
  final double load; // Define tu métrica (p.ej., sRPE * minutos)
  final List<WorkoutExercise> exercises;

  const TrainingSession({
    required this.id,
    required this.day,
    required this.load,
    this.exercises = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day.name,
    'load': load,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id'] as String? ?? '',
    day: ModelUtils.enumByName(DayOfWeek.values, json['day'] as String?, DayOfWeek.mon),
    load: (json['load'] as num?)?.toDouble() ?? 0,
    exercises: ((json['exercises'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(WorkoutExercise.fromJson)
      .toList(),
  );

  TrainingSession copyWith({
    String? id,
    DayOfWeek? day,
    double? load,
    List<WorkoutExercise>? exercises,
  }) => TrainingSession(
    id: id ?? this.id,
    day: day ?? this.day,
    load: load ?? this.load,
    exercises: exercises ?? this.exercises,
  );

  @override
  String toString() => 'TrainingSession(id: $id, day: ${day.name}, load: $load, exercises: ${exercises.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSession &&
        other.id == id &&
        other.day == day &&
        other.load == load &&
        listEquals(other.exercises, exercises);

  @override
  int get hashCode => id.hashCode ^ day.hashCode ^ load.hashCode ^ exercises.hashCode;
}
