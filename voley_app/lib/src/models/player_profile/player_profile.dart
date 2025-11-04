import 'package:voley_app/src/models/player_profile/availability.dart';
import 'package:voley_app/src/models/player_profile/evaluation_result.dart';
import 'package:voley_app/src/models/player_profile/form_peak.dart';
import 'package:voley_app/src/models/player_profile/player_event.dart';
import 'package:voley_app/src/models/player_profile/tournament.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerProfile {
  final String id;
  final String? userId; // Link to User document
  final String name;
  final String position;
  final String level; // "recreativo", "competitivo", "semiprofesional"
  final List<String> goals;
  final List<String> injuries;
  final List<String> chronicConditions;
  final Availability availability;
  final EvaluationResult evaluation;
  final List<Tournament> tournaments;
  final String? assignedCoachId; // UID del entrenador asignado
  final List<String> equipment; // Equipamiento disponible
  final int? age;
  final DateTime? birthDate;
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
    required this.goals,
    required this.injuries,
    required this.availability,
    required this.evaluation,
    required this.tournaments,
    this.assignedCoachId,
    this.equipment = const [],
    this.age,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.wingspanCm,
    this.keyEvents = const [],
    this.formPeaks = const [],
    this.chronicConditions = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'position': position,
        'level': level,
        'goals': goals,
        'injuries': injuries,'chronicConditions': chronicConditions,
        'availability': availability.toJson(),
        'evaluation': evaluation.toJson(),
        'tournaments': tournaments.map((t) => t.toJson()).toList(),
        'assignedCoachId': assignedCoachId,
        'equipment': equipment,
        'age': age,
        'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
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
        goals: List<String>.from(json['goals'] ?? []),
        injuries: List<String>.from(json['injuries'] ?? []),
        chronicConditions: List<String>.from(json['chronicConditions'] ?? []),
        availability: Availability.fromJson(Map<String, dynamic>.from(json['availability'] ?? {})),
        evaluation: EvaluationResult.fromJson(Map<String, dynamic>.from(json['evaluation'] ?? {})),
        tournaments: (json['tournaments'] as List<dynamic>? ?? [])
            .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
        assignedCoachId: json['assignedCoachId'] as String?,
        equipment: List<String>.from(json['equipment'] ?? []),
        age: json['age'] as int?,
        birthDate: json['birthDate'] == null
            ? null
            : json['birthDate'] is Timestamp
                ? (json['birthDate'] as Timestamp).toDate()
                : DateTime.tryParse(json['birthDate'].toString()),
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
    List<String>? chronicConditions,
    Availability? availability,
    EvaluationResult? evaluation,
    List<Tournament>? tournaments,
    List<String>? equipment,
    int? age,
    DateTime? birthDate,
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
      goals: goals ?? this.goals,
      injuries: injuries ?? this.injuries,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      availability: availability ?? this.availability,
      evaluation: evaluation ?? this.evaluation,
      tournaments: tournaments ?? this.tournaments,
      equipment: equipment ?? this.equipment,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      wingspanCm: wingspanCm ?? this.wingspanCm,
      keyEvents: keyEvents ?? this.keyEvents,
      formPeaks: formPeaks ?? this.formPeaks,
    );
  }
}