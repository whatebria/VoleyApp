import 'package:voley_app/src/models/program/mesocycle.dart';
import 'package:voley_app/src/models/program/microcycle.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

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
  List<Microcycle> generateMicrocyclesFromTemplate({
    required int weeks,
    required Microcycle templateMicro,
  }) {
    final templateSessions = templateMicro.sessions;
    final totalWeeks = weeks;

    return List.generate(weeks, (i) {
      final newSessions = templateSessions.map((templateSession) {
        // Copia profunda de cada sección de ejercicios
        List<WorkoutExercise> cloneExercises(List<WorkoutExercise> source) =>
            source
                .map((exercise) =>
                    exercise.copyWith(exerciseId: _uuid.v4()))
                .toList();

        final newWarmUpExercises =
            cloneExercises(templateSession.warmUpExercises);
        final newTrainingExercises =
            cloneExercises(templateSession.trainingExercises);
        final newCoolDownExercises =
            cloneExercises(templateSession.coolDownExercises);

        // Copia la sesión, pero actualiza ID y Carga
        return templateSession.copyWith(
          id: _uuid.v4(),
          load: suggestedLoadFor(i, totalWeeks), // Recalcula la carga
          warmUpExercises: newWarmUpExercises,
          trainingExercises: newTrainingExercises,
          coolDownExercises: newCoolDownExercises,
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
      progressionType: ProgressionType.linear, // <- enum
      matchDayIndex: 5, // Sábado si usas 0..6 (Mon..Sun)
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
