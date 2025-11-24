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
  final List<WorkoutExercise> warmUpExercises;
  final List<WorkoutExercise> trainingExercises;
  final List<WorkoutExercise> coolDownExercises;

  const TrainingSession({
    required this.id,
    required this.day,
    required this.load,
    this.exercises = const [],
    this.warmUpExercises = const [],
    this.trainingExercises = const [],
    this.coolDownExercises = const [],
  });

  List<WorkoutExercise> get allExercises => [
    ...warmUpExercises,
    ...trainingExercises,
    ...coolDownExercises,
  ];

  int get totalExercises => allExercises.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day.name,
    'load': load,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'warmUpExercises': warmUpExercises.map((e) => e.toJson()).toList(),
    'trainingExercises': trainingExercises.map((e) => e.toJson()).toList(),
    'coolDownExercises': coolDownExercises.map((e) => e.toJson()).toList(),
  };

  static TrainingSession fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id'] as String? ?? '',
    day: ModelUtils.enumByName(
      DayOfWeek.values,
      json['day'] as String?,
      DayOfWeek.mon,
    ),
    load: (json['load'] as num?)?.toDouble() ?? 0,
    warmUpExercises: _parseExerciseList(json['warmUpExercises']),
    trainingExercises: _parseTrainingExercises(json),
    coolDownExercises: _parseExerciseList(json['coolDownExercises']),
  );

  TrainingSession copyWith({
    String? id,
    DayOfWeek? day,
    double? load,
    List<WorkoutExercise>? warmUpExercises,
    List<WorkoutExercise>? trainingExercises,
    List<WorkoutExercise>? coolDownExercises,
  }) => TrainingSession(
    id: id ?? this.id,
    day: day ?? this.day,
    load: load ?? this.load,
    warmUpExercises: warmUpExercises ?? this.warmUpExercises,
    trainingExercises: trainingExercises ?? this.trainingExercises,
    coolDownExercises: coolDownExercises ?? this.coolDownExercises,
  );

  @override
  String toString() =>
      'TrainingSession(id: $id, day: ${day.name}, load: $load, warmUp: ${warmUpExercises.length}, training: ${trainingExercises.length}, coolDown: ${coolDownExercises.length})';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSession &&
          other.id == id &&
          other.day == day &&
          other.load == load &&
          listEquals(other.warmUpExercises, warmUpExercises) &&
          listEquals(other.trainingExercises, trainingExercises) &&
          listEquals(other.coolDownExercises, coolDownExercises);

  @override
  int get hashCode =>
      id.hashCode ^
      day.hashCode ^
      load.hashCode ^
      warmUpExercises.hashCode ^
      trainingExercises.hashCode ^
      coolDownExercises.hashCode;
}

List<WorkoutExercise> _parseTrainingExercises(Map<String, dynamic> json) {
  final trainingList = ((json['trainingExercises'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(WorkoutExercise.fromJson)
      .toList();

  if (trainingList.isNotEmpty) return trainingList;

  // Retrocompatibilidad con datos antiguos que guardaban todo en 'exercises'
  return ((json['exercises'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(WorkoutExercise.fromJson)
      .toList();
}

List<WorkoutExercise> _parseExerciseList(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map<String, dynamic>>()
      .map(WorkoutExercise.fromJson)
      .toList();
}
