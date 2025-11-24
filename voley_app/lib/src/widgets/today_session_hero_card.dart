import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';

class TodaySessionHeroCard extends StatelessWidget {
  const TodaySessionHeroCard({
    super.key,
    required this.date,
    required this.session,
    required this.completedLog,
    required this.onStart,
    required this.onViewLog,
  });

  final DateTime date;
  final TrainingSession? session;
  final SessionLog? completedLog;
  final VoidCallback? onStart;
  final VoidCallback? onViewLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('dd/MM').format(date);
    final hasSession = session != null;
    final isCompleted = completedLog != null;

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
                  'Sesión de hoy',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Día $dateLabel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                if (hasSession)
                  _SessionDetails(
                    session: session!,
                    theme: theme,
                  )
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
                      isCompleted ? Icons.visibility_rounded : Icons.play_arrow_rounded,
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
            hasSession ? Icons.fitness_center_rounded : Icons.coffee_rounded,
            size: 42,
            color: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _SessionDetails extends StatelessWidget {
  const _SessionDetails({
    required this.session,
    required this.theme,
  });

  final TrainingSession session;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final focusExercise = _firstExercise(session.trainingExercises);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${session.totalExercises} ejercicios planificados',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (focusExercise != null) ...[
          const SizedBox(height: 4),
          Text(
            'Primer foco: $focusExercise',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ],
    );
  }

  String? _firstExercise(List<WorkoutExercise> exercises) {
    if (exercises.isEmpty) return null;
    return exercises.first.name.isNotEmpty ? exercises.first.name : null;
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
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
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