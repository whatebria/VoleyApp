import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:voley_app/src/models/program/logged_excercise.dart';
import 'package:voley_app/utils/common/utils.dart';

@immutable
class SetLog {
  final int setNumber;
  final int reps;
  final double weight; // kg
  final double? rpe;

  const SetLog({
    required this.setNumber,
    required this.reps,
    required this.weight,
    this.rpe,
  });

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'rpe': rpe,
  };

  static SetLog fromJson(Map<String, dynamic> json) => SetLog(
    setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0,
    rpe: (json['rpe'] as num?)?.toDouble(),
  );

  SetLog copyWith({int? setNumber, int? reps, double? weight, double? rpe}) =>
      SetLog(
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        rpe: rpe ?? this.rpe,
      );

  @override
  String toString() => 'SetLog(#$setNumber, reps: $reps, kg: $weight, rpe: $rpe)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetLog &&
        other.setNumber == setNumber &&
        other.reps == reps &&
        other.weight == weight &&
        other.rpe == rpe;

  @override
  int get hashCode => setNumber.hashCode ^ reps.hashCode ^ weight.hashCode ^ rpe.hashCode;
}

/// Resultado completo de una sesión ejecutada por el atleta.
@immutable
class SessionLog {
  final String id;
  final String profileId;
  final String sessionId;      // referencia a TrainingSession
  final DateTime completedAt;
  final List<LoggedExercise> loggedExercises;
  final double rpe;            // 1..10
  final String? notes;

  const SessionLog({
    required this.id,
    required this.profileId,
    required this.sessionId,
    required this.completedAt,
    this.loggedExercises = const [],
    this.rpe = 0,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'sessionId': sessionId,
    'completedAt': completedAt.toIso8601String(),
    'loggedExercises': loggedExercises.map((e) => e.toJson()).toList(),
    'rpe': rpe,
    'notes': notes,
  };

  static SessionLog fromJson(Map<String, dynamic> json) => SessionLog(
    id: json['id'] as String? ?? '',
    profileId: json['profileId'] as String? ?? '',
    sessionId: json['sessionId'] as String? ?? '',
    completedAt: ModelUtils.parseDateFlex(json['completedAt']) ?? DateTime.now(),
    loggedExercises: ((json['loggedExercises'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(LoggedExercise.fromJson)
      .toList(),
    rpe: (json['rpe'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String?,
  );

  SessionLog copyWith({
    String? id,
    String? profileId,
    String? sessionId,
    DateTime? completedAt,
    List<LoggedExercise>? loggedExercises,
    double? rpe,
    String? notes,
  }) => SessionLog(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    sessionId: sessionId ?? this.sessionId,
    completedAt: completedAt ?? this.completedAt,
    loggedExercises: loggedExercises ?? this.loggedExercises,
    rpe: rpe ?? this.rpe,
    notes: notes ?? this.notes,
  );

  @override
  String toString() =>
      'SessionLog(id: $id, profile: $profileId, session: $sessionId, at: ${completedAt.toIso8601String()}, rpe: $rpe, sets: ${loggedExercises.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionLog &&
      other.id == id &&
      other.profileId == profileId &&
      other.sessionId == sessionId &&
      other.completedAt == completedAt &&
      const DeepCollectionEquality().equals(other.loggedExercises, loggedExercises) &&
      other.rpe == rpe &&
      other.notes == notes;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      profileId.hashCode ^
      sessionId.hashCode ^
      completedAt.hashCode ^
      const DeepCollectionEquality().hash(loggedExercises) ^
      rpe.hashCode ^
      notes.hashCode;
}
