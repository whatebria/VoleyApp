// lib/models/athlete.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para el documento en la colección 'athletes'.
class Athlete {
  final String uid; // El ID del documento (UID de Firebase Auth)
  final String name;
  final String birthDate;
  final String sex;
  final String email;
  final double height;
  final double weight;
  final String position;
  final String level;
  final Availability availability;
  final List<String> goals;
  final List<AthleteInjury> injuries;
  final bool hasTournamentSoon;
  final String tournamentDate;
  final String priority;
  final String currentPhase;
  final String currentProgramId;
  final String lastEvaluationDate;
  final String createdAt;
  final String updatedAt;

  Athlete({
    required this.uid,
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.email,
    required this.height,
    required this.weight,
    required this.position,
    required this.level,
    required this.availability,
    required this.goals,
    required this.injuries,
    required this.hasTournamentSoon,
    required this.tournamentDate,
    required this.priority,
    required this.currentPhase,
    required this.currentProgramId,
    required this.lastEvaluationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea un [Athlete] desde un [DocumentSnapshot] de Firebase.
  factory Athlete.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parsear la lista de lesiones
    final injuryList = data['injuries'] as List<dynamic>? ?? [];
    final injuries = injuryList
        .map((injuryData) =>
            AthleteInjury.fromMap(injuryData as Map<String, dynamic>))
        .toList();

    return Athlete(
      uid: doc.id,
      name: data['name'] ?? '',
      birthDate: data['birthDate'] ?? '',
      sex: data['sex'] ?? '',
      email: data['email'] ?? '',
      height: (data['height'] ?? 0.0).toDouble(),
      weight: (data['weight'] ?? 0.0).toDouble(),
      position: data['position'] ?? '',
      level: data['level'] ?? '',
      availability: Availability.fromMap(data['availability'] ?? {}),
      goals: List<String>.from(data['goals'] ?? []),
      injuries: injuries,
      hasTournamentSoon: data['hasTournamentSoon'] ?? false,
      tournamentDate: data['tournamentDate'] ?? '',
      priority: data['priority'] ?? '',
      currentPhase: data['currentPhase'] ?? '',
      currentProgramId: data['currentProgramId'] ?? '',
      lastEvaluationDate: data['lastEvaluationDate'] ?? '',
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
    );
  }

  /// Convierte el objeto [Athlete] a un [Map] para Firebase.
  /// El 'uid' no se incluye porque es el ID del documento.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'birthDate': birthDate,
      'sex': sex,
      'email': email,
      'height': height,
      'weight': weight,
      'position': position,
      'level': level,
      'availability': availability.toMap(),
      'goals': goals,
      'injuries': injuries.map((injury) => injury.toMap()).toList(),
      'hasTournamentSoon': hasTournamentSoon,
      'tournamentDate': tournamentDate,
      'priority': priority,
      'currentPhase': currentPhase,
      'currentProgramId': currentProgramId,
      'lastEvaluationDate': lastEvaluationDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// --- Clases Auxiliares Anidadas ---

/// Modelo para el objeto 'availability'
class Availability {
  final int daysPerWeek;
  final List<String> preferredDays;

  Availability({
    required this.daysPerWeek,
    required this.preferredDays,
  });

  factory Availability.fromMap(Map<String, dynamic> map) {
    return Availability(
      daysPerWeek: map['daysPerWeek'] ?? 0,
      preferredDays: List<String>.from(map['preferredDays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'daysPerWeek': daysPerWeek,
      'preferredDays': preferredDays,
    };
  }
}

/// Modelo para los objetos en la lista 'injuries'
class AthleteInjury {
  final String type;
  final String status;
  final String startDate;

  AthleteInjury({
    required this.type,
    required this.status,
    required this.startDate,
  });

  factory AthleteInjury.fromMap(Map<String, dynamic> map) {
    return AthleteInjury(
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      startDate: map['startDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'startDate': startDate,
    };
  }
}