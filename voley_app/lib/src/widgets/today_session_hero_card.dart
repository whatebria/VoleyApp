import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

class SessionVisuals {
  const SessionVisuals({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

class TodaySessionHeroCard extends StatelessWidget {
  const TodaySessionHeroCard({
    super.key,
    required this.date,
    required this.session,
    required this.completedLog,
    required this.onStart,
    required this.onViewLog,
    required this.isToday,
    this.sessionVisuals,
  });

  final DateTime date;
  final TrainingSession? session;
  final SessionLog? completedLog;
  final VoidCallback? onStart;
  final VoidCallback? onViewLog;
  final bool isToday;
  final SessionVisuals? sessionVisuals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('dd/MM').format(date);
    final hasSession = session != null;
    final isCompleted = completedLog != null;
    final iconData = sessionVisuals?.icon ?? Icons.fitness_center_rounded;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.9),
            theme.colorScheme.secondary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusChip(
                  isCompleted: isCompleted,
                  theme: theme,
                  hasSession: hasSession,
                ),
                const SizedBox(height: 8),
                Text(
                  isToday ? 'Sesión de hoy' : 'Sesión seleccionada',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${isToday ? 'Hoy • ' : ''} $dateLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (hasSession)
                  _SessionDetails(session: session!, theme: theme)
                else
                  Text(
                    'No tienes entrenamiento para hoy. Disfruta tu descanso 👟',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: hasSession
                        ? (isCompleted ? onViewLog : onStart)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.onPrimary,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      isCompleted
                          ? Icons.visibility_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      hasSession
                          ? (isCompleted ? 'Ver registro' : 'Comenzar sesión')
                          : 'Sin sesión',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            hasSession ? iconData : Icons.coffee_rounded,
            size: 42,
            color: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _SessionDetails extends StatelessWidget {
  const _SessionDetails({required this.session, required this.theme});

  final TrainingSession session;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Tomamos todos los ejercicios “reales” de la sesión
    // Preferimos trainingExercises, pero si está vacío,
    // podemos caer en allExercises si tu modelo lo tiene.
    final List<WorkoutExercise> allExercises = session.trainingExercises.isNotEmpty
        ? session.trainingExercises
        : (session.allExercises); // si no existe allExercises, quita esto y deja solo trainingExercises

    final int total = allExercises.length;
    final List<WorkoutExercise> preview = allExercises.take(3).toList();

    final String? focusExercise = _firstExerciseName(allExercises);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea de resumen principal
        Text(
          '$total ejercicios planificados',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Hoy trabajas:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // Chips con algunos ejercicios
              ...preview.map((ex) {
                return _ExercisePill(
                  label: ex.name,
                  theme: theme,
                );
              }),
              if (total > preview.length)
                _ExercisePill(
                  label: '+${total - preview.length} más',
                  theme: theme,
                  isMoreChip: true,
                ),
            ],
          ),
        ],
      ],
    );
  }

  String? _firstExerciseName(List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) return null;
    final first = exercises.first;
    if (first.name.trim().isEmpty) return null;
    return first.name;
  }
}

// Pequeño pill reutilizable para mostrar ejercicios
class _ExercisePill extends StatelessWidget {
  const _ExercisePill({
    required this.label,
    required this.theme,
    this.isMoreChip = false,
  });

  final String label;
  final ThemeData theme;
  final bool isMoreChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(isMoreChip ? 0.12 : 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: isMoreChip ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}


class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.isCompleted,
    required this.theme,
    required this.hasSession,
  });

  final bool isCompleted;
  final ThemeData theme;
  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    final label = !hasSession
        ? 'Descanso'
        : isCompleted
        ? 'Completada'
        : 'Planificada';
    final color = !hasSession
        ? theme.colorScheme.surfaceTint
        : isCompleted
        ? theme.colorScheme.tertiary
        : theme.colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
