// lib/src/models/program/microcicle.dart
import 'package:voley_app/src/models/program/training_session.dart'; // Ajusta el path

class Microcycle {
  final int weekNumber;
  final List<TrainingSession> sessions;

  Microcycle({required this.weekNumber, required this.sessions});

  // --- CONSTRUCTOR fromJson CORREGIDO Y SEGURO ---
  factory Microcycle.fromJson(Map<String, dynamic> json) {
    return Microcycle(
      weekNumber: json['weekNumber'] as int? ?? 0,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}