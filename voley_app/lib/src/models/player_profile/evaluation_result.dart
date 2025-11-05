import 'package:cloud_firestore/cloud_firestore.dart'; // Para Timestamps
// --- AÑADIDO: Import del nuevo modelo ---
import 'package:voley_app/src/models/player_profile/test_score.dart';

class EvaluationResult {
  final DateTime date;
  // --- CAMBIO: El tipo ahora es una lista de objetos TestScore ---
  final List<TestScore> testScores;
  // (Opcional) final String? notes; // Notas del entrenador, etc.

  EvaluationResult({
    required this.date,
    this.testScores = const [], // Valor por defecto es una lista vacía
    // this.notes,
  });

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date), // Guardar como Timestamp en Firestore
        // --- CAMBIO: Mapea la lista de objetos a JSON ---
        'testScores': testScores.map((score) => score.toJson()).toList(),
        // 'notes': notes,
      };

  static EvaluationResult fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      // Leer como Timestamp y convertir a DateTime
      date: (json['date'] as Timestamp? ?? Timestamp.now()).toDate(),
      // --- CAMBIO: Parsea la lista de JSON a una lista de TestScore ---
      testScores: (json['testScores'] as List<dynamic>? ?? [])
          .map((scoreJson) =>
              TestScore.fromJson(scoreJson as Map<String, dynamic>))
          .toList(),
      // notes: json['notes'] as String?,
    );
  }

  // --- AÑADIDO: Método copyWith para gestión de estado inmutable ---
  EvaluationResult copyWith({
    DateTime? date,
    List<TestScore>? testScores,
    // String? notes,
  }) {
    return EvaluationResult(
      date: date ?? this.date,
      testScores: testScores ?? this.testScores,
      // notes: notes ?? this.notes,
    );
  }

  // --- Opcional: Métodos de igualdad para comparaciones ---
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is EvaluationResult &&
      other.date == date &&
      // Compara las listas
      ListEquality().equals(other.testScores, testScores);
  }

  @override
  int get hashCode => date.hashCode ^ testScores.hashCode;
}

