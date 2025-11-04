import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:uuid/uuid.dart';

/// Clase de lógica de negocio para generar y manipular estructuras de programas.
class ProgramGenerator {
  final Uuid _uuid = const Uuid();

  /// Calcula la carga sugerida para una semana basada en una progresión lineal.
  double suggestedLoadFor(int weekIndex, int totalWeeks) {
    final normalizedIndex = totalWeeks <= 1 ? 0 : weekIndex / (totalWeeks - 1);
    // Progresión lineal simple de 0.6 a 0.85
    return double.parse((0.6 + 0.25 * normalizedIndex).toStringAsFixed(2));
  }

  /// Genera una lista de microciclos (semanas) basados en una plantilla.
  List<Microcycle> generateMicrocyclesFromTemplate(
      {required int weeks, required Microcycle templateMicro}) {
    final templateSessions = templateMicro.sessions;
    final totalWeeks = weeks;

    return List.generate(weeks, (i) {
      final newSessions = templateSessions.map((templateSession) {
        // Copia profunda de ejercicios
        final newExercises = templateSession.exercises
            .map((e) => e.copyWith(exerciseId: _uuid.v4()))
            .toList();

        // Copia la sesión, pero actualiza ID y Carga
        return templateSession.copyWith(
          id: _uuid.v4(),
          load: suggestedLoadFor(i, totalWeeks), // Recalcula la carga
          exercises: newExercises,
        );
      }).toList();

      return Microcycle(
        weekNumber: i + 1,
        sessions: newSessions,
        id: _uuid.v4(),
      );
    });
  }

  /// Crea un Mesociclo (Bloque) completamente nuevo.
  Mesocycle createNewMesocycle({
    required String name,
    required String objective,
    required int weeks,
    required Microcycle templateMicro,
  }) {
    final microcycles = generateMicrocyclesFromTemplate(
      weeks: weeks,
      templateMicro: templateMicro,
    );

    return Mesocycle(
      id: _uuid.v4(),
      name: name,
      objective: objective,
      weeks: weeks,
      focus: "Personalizado",
      progressionType: 'lineal',
      matchDayIndex: 5, // Sábado (valor por defecto)
      microcycles: microcycles,
    );
  }

  /// Actualiza un Mesociclo (Bloque) existente con nuevos datos.
  Mesocycle updateMesocycle({
    required Mesocycle mesoToEdit,
    required String name,
    required String objective,
    required int weeks,
    required Microcycle templateMicro,
  }) {
    // Regenera los microciclos basados en la nueva plantilla y duración
    final microcycles = generateMicrocyclesFromTemplate(
      weeks: weeks,
      templateMicro: templateMicro,
    );

    return mesoToEdit.copyWith(
      name: name,
      objective: objective,
      weeks: weeks,
      microcycles: microcycles,
      // Mantenemos el focus, progressionType y matchDayIndex del original
      focus: mesoToEdit.focus,
      progressionType: mesoToEdit.progressionType,
      matchDayIndex: mesoToEdit.matchDayIndex,
    );
  }
}
