import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/goal.dart';
import 'package:voley_app/src/models/player_profile/injury.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
// --- AÑADIDO: Imports para los nuevos modelos ---

class PlayerProfile {
  final String id;
  final String? userId; // Link to User document
  final String name;
  final String position;
  final String level; // "recreativo", "competitivo", "semiprofesional"
  // --- CAMBIO: Actualizado de List<String> a List<Goal> ---
  final List<Goal> goals;
  // --- CAMBIO: Actualizado de List<String> a List<Injury> ---
  final List<Injury> injuries;
  final Availability availability;
  final List<EvaluationResult> evaluationHistory;
  final List<Tournament> tournaments;
  final String? assignedCoachId; // UID del entrenador asignado
  final List<String> equipmentIds; // Equipamiento disponible
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? wingspanCm;
  final List<PlayerEvent> keyEvents;
  final List<FormPeak> formPeaks;

  PlayerProfile({
    required this.id,
    this.userId,
    required this.name,
    required this.position,
    required this.level,
    // --- CAMBIO: Valor por defecto const [] ---
    this.goals = const [],
    this.injuries = const [],
    required this.availability,
    this.evaluationHistory = const [],
    required this.tournaments,
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
        'position': position,
        'level': level,
        // --- CAMBIO: Mapea los objetos Goal a JSON ---
        'goals': goals.map((g) => g.toJson()).toList(),
        // --- CAMBIO: Mapea los objetos Injury a JSON ---
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
        position: json['position'] as String? ?? 'Sin posición',
        level: json['level'] as String? ?? 'recreativo',
        // --- CAMBIO: Parsea la lista de JSON a objetos Goal ---
        goals: (json['goals'] as List<dynamic>? ?? [])
            .map((g) => Goal.fromJson(Map<String, dynamic>.from(g)))
            .toList(),
        // --- CAMBIO: Parsea la lista de JSON a objetos Injury ---
        injuries: (json['injuries'] as List<dynamic>? ?? [])
            .map((i) => Injury.fromJson(Map<String, dynamic>.from(i)))
            .toList(),
        availability: Availability.fromJson(Map<String, dynamic>.from(json['availability'] ?? {})),
        evaluationHistory: (json['evaluationHistory'] as List<dynamic>? ?? [])
            .map((e) => EvaluationResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        tournaments: (json['tournaments'] as List<dynamic>? ?? [])
            .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
        assignedCoachId: json['assignedCoachId'] as String?,
        equipmentIds: List<String>.from(json['equipmentIds'] ?? []),
        age: json['age'] as int?,
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        wingspanCm: (json['wingspanCm'] as num?)?.toDouble(),
        keyEvents: (json['keyEvents'] as List<dynamic>? ?? [])
            .map((event) => PlayerEvent.fromJson(Map<String, dynamic>.from(event)))
            .toList(),
        formPeaks: (json['formPeaks'] as List<dynamic>? ?? [])
            .map((peak) => FormPeak.fromJson(Map<String, dynamic>.from(peak)))
            .toList(),
      );

  PlayerProfile copyWith({
    String? id,
    String? userId,
    String? assignedCoachId,
    String? name,
    String? position,
    String? level,
    // --- CAMBIO: Tipo actualizado a List<Goal> ---
    List<Goal>? goals,
    // --- CAMBIO: Tipo actualizado a List<Injury> ---
    List<Injury>? injuries,
    Availability? availability,
    List<EvaluationResult>? evaluationHistory,
    List<Tournament>? tournaments,
    List<String>? equipmentIds,
    int? age,
    double? heightCm,
    double? weightKg,
    double? wingspanCm,
    List<PlayerEvent>? keyEvents,
    List<FormPeak>? formPeaks,
  }) {
    return PlayerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignedCoachId: assignedCoachId ?? this.assignedCoachId,
      name: name ?? this.name,
      position: position ?? this.position,
      level: level ?? this.level,
      // --- CAMBIO: Actualizado ---
      goals: goals ?? this.goals,
      // --- CAMBIO: Actualizado ---
      injuries: injuries ?? this.injuries,
      availability: availability ?? this.availability,
      evaluationHistory: evaluationHistory ?? this.evaluationHistory,
      tournaments: tournaments ?? this.tournaments,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      wingspanCm: wingspanCm ?? this.wingspanCm,
      keyEvents: keyEvents ?? this.keyEvents,
      formPeaks: formPeaks ?? this.formPeaks,
    );
  }
  
  EvaluationResult? get latestEvaluation {
    if (evaluationHistory.isEmpty) return null;
    // Asume que la lista puede no estar ordenada, así que la ordenamos
    // (Idealmente, tu provider la ordena una vez al cargarla)
    final sortedHistory = List<EvaluationResult>.from(evaluationHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedHistory.first;
  }
}