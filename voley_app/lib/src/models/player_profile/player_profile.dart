import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';
import 'availability.dart';
import 'evaluation_result.dart';
import 'form_peak.dart';
import 'goal.dart';
import 'injury.dart';
import 'player_event.dart';
import 'tournament.dart';

enum PlayerLevel { recreativo, competitivo, semiprofesional }
enum PlayerPosition { oh, mb, s, l, op } // Outside, Middle, Setter, Libero, Opposite

@immutable
class PlayerProfile {
  final String id;
  final String? userId; // link a User
  final String name;
  final PlayerPosition position;
  final PlayerLevel level;
  final List<Goal> goals;
  final List<Injury> injuries;
  final Availability availability;

  /// Mantengo tu historial + getter de última evaluación
  final List<EvaluationResult> evaluationHistory;

  final List<Tournament> tournaments;
  final String? assignedCoachId;
  final List<String> equipmentIds; // ids o enum.name de equipos disponibles

  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? wingspanCm;

  final List<PlayerEvent> keyEvents;
  final List<FormPeak> formPeaks;

  const PlayerProfile({
    required this.id,
    this.userId,
    required this.name,
    required this.position,
    required this.level,
    this.goals = const [],
    this.injuries = const [],
    this.availability = const Availability(),
    this.evaluationHistory = const [],
    this.tournaments = const [],
    this.assignedCoachId,
    this.equipmentIds = const [],
    this.age,
    this.heightCm,
    this.weightKg,
    this.wingspanCm,
    this.keyEvents = const [],
    this.formPeaks = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'position': position.name,
        'level': level.name,
        'goals': goals.map((g) => g.toJson()).toList(),
        'injuries': injuries.map((i) => i.toJson()).toList(),
        'availability': availability.toJson(),
        'evaluationHistory': evaluationHistory.map((e) => e.toJson()).toList(),
        'tournaments': tournaments.map((t) => t.toJson()).toList(),
        'assignedCoachId': assignedCoachId,
        'equipmentIds': equipmentIds,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'wingspanCm': wingspanCm,
        'keyEvents': keyEvents.map((e) => e.toJson()).toList(),
        'formPeaks': formPeaks.map((e) => e.toJson()).toList(),
      };

  static PlayerProfile fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String?,
        name: json['name'] as String? ?? 'Jugador',
        position: ModelUtils.enumByName(
          PlayerPosition.values,
          json['position'] as String?,
          PlayerPosition.oh,
        ),
        level: ModelUtils.enumByName(
          PlayerLevel.values,
          json['level'] as String?,
          PlayerLevel.competitivo,
        ),
        goals: ((json['goals'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Goal.fromJson)
            .toList(),
        injuries: ((json['injuries'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Injury.fromJson)
            .toList(),
        availability: json['availability'] is Map<String, dynamic>
            ? Availability.fromJson(json['availability'] as Map<String, dynamic>)
            : const Availability(),
        evaluationHistory: ((json['evaluationHistory'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(EvaluationResult.fromJson)
            .toList(),
        tournaments: ((json['tournaments'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(Tournament.fromJson)
            .toList(),
        assignedCoachId: json['assignedCoachId'] as String?,
        equipmentIds: ((json['equipmentIds'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        age: (json['age'] as num?)?.toInt(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        wingspanCm: (json['wingspanCm'] as num?)?.toDouble(),
        keyEvents: ((json['keyEvents'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PlayerEvent.fromJson)
            .toList(),
        formPeaks: ((json['formPeaks'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(FormPeak.fromJson)
            .toList(),
      );

  EvaluationResult? get latestEvaluation {
    if (evaluationHistory.isEmpty) return null;
    final sorted = List<EvaluationResult>.from(evaluationHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  PlayerProfile copyWith({
    String? id,
    String? userId,
    String? name,
    PlayerPosition? position,
    PlayerLevel? level,
    List<Goal>? goals,
    List<Injury>? injuries,
    Availability? availability,
    List<EvaluationResult>? evaluationHistory,
    List<Tournament>? tournaments,
    String? assignedCoachId,
    List<String>? equipmentIds,
    int? age,
    double? heightCm,
    double? weightKg,
    double? wingspanCm,
    List<PlayerEvent>? keyEvents,
    List<FormPeak>? formPeaks,
  }) =>
      PlayerProfile(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        position: position ?? this.position,
        level: level ?? this.level,
        goals: goals ?? this.goals,
        injuries: injuries ?? this.injuries,
        availability: availability ?? this.availability,
        evaluationHistory: evaluationHistory ?? this.evaluationHistory,
        tournaments: tournaments ?? this.tournaments,
        assignedCoachId: assignedCoachId ?? this.assignedCoachId,
        equipmentIds: equipmentIds ?? this.equipmentIds,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        wingspanCm: wingspanCm ?? this.wingspanCm,
        keyEvents: keyEvents ?? this.keyEvents,
        formPeaks: formPeaks ?? this.formPeaks,
      );
}
