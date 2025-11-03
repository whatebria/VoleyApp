import 'package:voley_app/src/models/program/training_session.dart';

class Microcycle {
  final String id; // <--- NUEVA PROPIEDAD CRÍTICA
  final int weekNumber;
  final List<TrainingSession> sessions;
  // Puedes añadir más propiedades (ej. focus, load) si tu app las usa.

  const Microcycle({
    required this.id, // <--- Requiere ID
    required this.weekNumber,
    required this.sessions,
  });

  // Método de fábrica para crear desde JSON (Firestore)
  factory Microcycle.fromJson(Map<String, dynamic> json) {
    return Microcycle(
      id: json['id'] as String? ?? '',
      weekNumber: json['weekNumber'] as int? ?? 0,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // Método para convertir a JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekNumber': weekNumber,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  // Método copyWith para inmutabilidad (esencial para setState en Flutter/Riverpod)
  Microcycle copyWith({
    String? id,
    int? weekNumber,
    List<TrainingSession>? sessions,
  }) {
    return Microcycle(
      id: id ?? this.id,
      weekNumber: weekNumber ?? this.weekNumber,
      sessions: sessions ?? this.sessions,
    );
  }
}