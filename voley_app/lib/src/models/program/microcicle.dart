// En microcicle.dart
import 'package:voley_app/src/models/program/training_session.dart';

class Microcycle {
  // (Tus campos)
  final int weekNumber;
  final List<TrainingSession> sessions;

  // (Tu constructor)
  Microcycle({required this.weekNumber, required this.sessions});

  // --- AÑADE ESTE CONSTRUCTOR ---
  factory Microcycle.fromJson(Map<String, dynamic> json) {
    return Microcycle(
      weekNumber: json['weekNumber'] ?? 0,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // (Tu método toJson)
  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}