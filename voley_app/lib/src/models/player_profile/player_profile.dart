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
      };

  static PlayerProfile fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        position: json['position'],
        level: json['level'],
        goals: List<String>.from(json['goals'] ?? []),
        injuries: List<String>.from(json['injuries'] ?? []),
        availability: Availability.fromJson(Map<String, dynamic>.from(json['availability'] ?? {})),
        evaluation: EvaluationResult.fromJson(Map<String, dynamic>.from(json['evaluation'] ?? {})),
        tournaments: (json['tournaments'] as List<dynamic>? ?? [])
            .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
      );
}