import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';

class PlayerProfile {
  final String id;
  final String? userId; // Link to User document
  final String name;
  final String position;
  final String level; // "recreativo", "competitivo", "semiprofesional"
  final List<String> goals;
  final List<String> injuries;
  final Availability availability;
  final EvaluationResult evaluation;
  final List<Tournament> tournaments;
  final String? assignedCoachId; // UID del entrenador asignado
  final List<String> equipment; // Equipamiento disponible

  PlayerProfile({
    required this.id,
    this.userId,
    required this.name,
    required this.position,
    required this.level,
    required this.goals,
    required this.injuries,
    required this.availability,
    required this.evaluation,
    required this.tournaments,
    this.assignedCoachId,
    this.equipment = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'position': position,
        'level': level,
        'goals': goals,
        'injuries': injuries,
        'availability': availability.toJson(),
        'evaluation': evaluation.toJson(),
        'tournaments': tournaments.map((t) => t.toJson()).toList(),
        'assignedCoachId': assignedCoachId,
        'equipment': equipment,
      };

  static PlayerProfile fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String?,
        name: json['name'] as String? ?? 'Jugador',
        position: json['position'] as String? ?? 'Sin posición',
        level: json['level'] as String? ?? 'recreativo',
        goals: List<String>.from(json['goals'] ?? []),
        injuries: List<String>.from(json['injuries'] ?? []),
        availability: Availability.fromJson(Map<String, dynamic>.from(json['availability'] ?? {})),
        evaluation: EvaluationResult.fromJson(Map<String, dynamic>.from(json['evaluation'] ?? {})),
        tournaments: (json['tournaments'] as List<dynamic>? ?? [])
            .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
        assignedCoachId: json['assignedCoachId'] as String?,
        equipment: List<String>.from(json['equipment'] ?? []),
      );
// --- AÑADE ESTE MÉTODO COMPLETO ---
  PlayerProfile copyWith({
    String? id,
    String? userId,
    String? assignedCoachId,
    String? name,
    String? position,
    String? level,
    List<String>? goals,
    List<String>? injuries,
    Availability? availability,
    EvaluationResult? evaluation,
    List<Tournament>? tournaments,
  }) {
    return PlayerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignedCoachId: assignedCoachId ?? this.assignedCoachId,
      name: name ?? this.name,
      position: position ?? this.position,
      level: level ?? this.level,
      goals: goals ?? this.goals,
      injuries: injuries ?? this.injuries,
      availability: availability ?? this.availability,
      evaluation: evaluation ?? this.evaluation,
      tournaments: tournaments ?? this.tournaments,
    );
  }
}