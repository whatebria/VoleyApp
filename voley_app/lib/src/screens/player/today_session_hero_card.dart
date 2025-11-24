import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/session_log.dart';

class TodaySessionHeroCard extends StatelessWidget {
  const TodaySessionHeroCard({
    super.key,
    required this.day,
    required this.program,
    required this.sessionsForDay,
    required this.historyForDay,
    this.onStartSession,
    this.onViewSummary,
  });

  /// Día que se está mostrando (normalmente DateTime.now() truncado a día)
  final DateTime day;

  /// Programa actual del jugador (puede ser null si quieres reutilizarlo en otro contexto)
  final Program? program;

  /// Sesiones planificadas para ese día (normalmente desde tu `events[normalizedDay]`)
  final List<TrainingSession> sessionsForDay;

  /// Logs asociados a las sesiones de ese día (filtrados desde tu historial)
  final List<SessionLog> historyForDay;

  /// Acción cuando el jugador quiere iniciar la sesión de hoy
  final void Function(TrainingSession session)? onStartSession;

  /// Acción cuando el jugador quiere ver el resumen de una sesión ya completada
  final void Function(TrainingSession session, SessionLog log)? onViewSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String dateLabel =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';

    final bool hasSession = sessionsForDay.isNotEmpty;

    // Tomamos la "sesión principal" del día: si hay varias, la primera.
    final TrainingSession? mainSession = hasSession ? sessionsForDay.first : null;

    // Buscamos si esa sesión principal tiene log asociado
    final SessionLog? mainLog = (mainSession != null)
        ? historyForDay.firstWhereOrNull((log) => log.sessionId == mainSession.id)
        : null;

    final bool isCompleted = mainLog != null;

    // Estados posibles:
    // 1) Sin sesión -> descanso
    // 2) Con sesión y sin log -> planificada
    // 3) Con sesión y con log -> completada

    final String title;
    final String subtitle;
    final IconData icon;
    final Color accentColor;
    final String? primaryActionLabel;

    if (!hasSession) {
      title = 'Día de descanso';
      subtitle = 'Aprovecha para recuperar y moverte suave.';
      icon = Icons.coffee_rounded;
      accentColor = theme.colorScheme.secondary;
      primaryActionLabel = null; // No hay CTA
    } else if (isCompleted) {
      title = 'Sesión completada';
      final rpe = mainLog!.rpe.toStringAsFixed(0);
      subtitle = 'RPE $rpe/10 • toca para ver el resumen.';
      icon = Icons.check_circle_rounded;
      accentColor = theme.colorScheme.primary;
      primaryActionLabel = 'Ver resumen';
    } else {
      // Sesión planificada
      title = 'Sesión planificada';
      final int totalExercises = mainSession!.allExercises.length;
      final String focus = mainSession.trainingExercises.isNotEmpty
          ? mainSession.trainingExercises.first.name
          : 'Entrenamiento del día';
      subtitle = '$totalExercises ejercicios • Foco: $focus';
      icon = Icons.flash_on_rounded;
      accentColor = theme.colorScheme.secondary;
      primaryActionLabel = 'Empezar sesión';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(0.16),
              accentColor.withOpacity(0.04),
            ],
          ),
          border: Border.all(
            color: accentColor.withOpacity(0.35),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icono + fecha
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.16),
              ),
              child: Icon(
                icon,
                size: 30,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            // Texto principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera fila: "Hoy · 24/11"
                  Row(
                    children: [
                      Text(
                        'Hoy',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '· $dateLabel',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (program != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            program!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // CTA (si existe)
            if (primaryActionLabel != null)
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    if (!hasSession) return;

                    if (!isCompleted && onStartSession != null) {
                      onStartSession!(mainSession!);
                    } else if (isCompleted && onViewSummary != null) {
                      onViewSummary!(mainSession!, mainLog!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: accentColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    primaryActionLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
