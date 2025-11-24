import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:collection/collection.dart';

import 'package:voley_app/providers/calendar_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/models/program/workout_exercise.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';
import 'package:voley_app/src/screens/player/workout_session_screen.dart';

class PlayerCalendarScreen extends ConsumerStatefulWidget {
  const PlayerCalendarScreen({super.key});

  @override
  _PlayerCalendarScreenState createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends ConsumerState<PlayerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _dayLabel(DayOfWeek d) => {
        DayOfWeek.mon: 'Lun',
        DayOfWeek.tue: 'Mar',
        DayOfWeek.wed: 'Mié',
        DayOfWeek.thu: 'Jue',
        DayOfWeek.fri: 'Vie',
        DayOfWeek.sat: 'Sáb',
        DayOfWeek.sun: 'Dom',
      }[d]!;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
  }

  List<TrainingSession> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<TrainingSession>> events,
  ) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserAppUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi entrenamiento'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Text('Error al cargar usuario: $e'),
          ),
          data: (user) {
            if (user == null || user.isCoach) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Acceso denegado.\nEsta pantalla es solo para jugadores.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final allProgramsAsync = ref.watch(playerProgramsProvider);
            final selectedProgram = ref.watch(selectedProgramProvider);
            final events = ref.watch(calendarEventsProvider);

            return allProgramsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error al cargar programa: $e')),
              data: (programs) {
                if (selectedProgram == null) {
                  return _buildNoProgramWidget(theme);
                }

                return Column(
                  children: [
                    _buildTopBar(theme, programs, selectedProgram),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildWeekCalendar(theme, selectedProgram, events),
                    ),
                    const SizedBox(height: 4),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                    Expanded(
                      child: ref.watch(sessionLogHistoryProvider).when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, s) => Center(
                              child: Text('Error al cargar historial: $e'),
                            ),
                            data: (historyList) {
                              final normalizedDay = _selectedDay != null
                                  ? DateTime(
                                      _selectedDay!.year,
                                      _selectedDay!.month,
                                      _selectedDay!.day,
                                    )
                                  : null;
                                

                              final selectedEvents = (normalizedDay != null &&
                                      events.containsKey(normalizedDay))
                                  ? events[normalizedDay]!
                                  : <TrainingSession>[];

                              return _buildEventList(
                                context,
                                theme,
                                historyList,
                                selectedEvents,
                              );
                            },
                          ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------- TOP BAR: Programa + fecha ----------
  Widget _buildTopBar(
    ThemeData theme,
    List<Program> programs,
    Program currentSelectedProgram,
  ) {
    final today = DateTime.now();
    final todayLabel =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          // Info hoy
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoy',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todayLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Selector de programa expandible, para evitar overflow en pantallas pequeñas
          Expanded(
            child: DropdownButtonFormField<Program>(
              value: currentSelectedProgram,
              isDense: true,
              isExpanded: true,
              items: programs.map((program) {
                return DropdownMenuItem<Program>(
                  value: program,
                  child: Text(
                    program.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Program? newProgram) {
                if (newProgram != null) {
                  ref.read(selectedProgramProvider.notifier).state = newProgram;

                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month,
                      _focusedDay.day,
                    );
                  });
                }
              },
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Programa',
                labelStyle: theme.textTheme.bodySmall,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
              ),
              icon: Icon(
                Icons.expand_more,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- CALENDARIO (SEMANA) ----------
  Widget _buildWeekCalendar(
    ThemeData theme,
    Program selectedProgram,
    Map<DateTime, List<TrainingSession>> events,
  ) {
    return TableCalendar<TrainingSession>(
      firstDay: selectedProgram.startDate.subtract(const Duration(days: 7)),
      lastDay: selectedProgram.endDate.add(const Duration(days: 7)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.week,
      availableCalendarFormats: const {
        CalendarFormat.week: 'Semana',
      },
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: theme.colorScheme.onSurface,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface,
        ),
      ),
      startingDayOfWeek: StartingDayOfWeek.monday,
      rowHeight: 46, // un poco más alto para mejor toque en móvil
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) => _getEventsForDay(day, events),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
          );
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        defaultTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
        weekendTextStyle: TextStyle(
          color: theme.colorScheme.secondary,
        ),
        outsideTextStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.35),
        ),
      ),
    );
  }

  // ---------- SIN PROGRAMA ----------
  Widget _buildNoProgramWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 72,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes un programa activo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Habla con tu entrenador para que te asigne un plan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- LISTA DE SESIONES DEL DÍA ----------
  Widget _buildEventList(
    BuildContext context,
    ThemeData theme,
    List<SessionLog> historyList,
    List<TrainingSession> selectedEvents,
  ) {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    // Día sin sesiones
    if (selectedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.coffee_outlined,
                size: 60,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Día de descanso',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No tienes sesiones planificadas para este día.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Hay al menos una sesión: mostramos un pequeño resumen + lista
    final bool anyCompletedForDay = selectedEvents.any((session) {
      return historyList.any((log) => log.sessionId == session.id);
    });

    final selectedDate = _selectedDay!;
    final selectedDateLabel =
        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}';

    final statusLabel = anyCompletedForDay
        ? 'Sesión completada'
        : 'Sesión planificada';

    final statusIcon =
        anyCompletedForDay ? Icons.check_circle_rounded : Icons.flash_on;

    final statusColor =
        anyCompletedForDay ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return Column(
      children: [
        // Resumen del día seleccionado
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Día $selectedDateLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: selectedEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = selectedEvents[index];

              final SessionLog? completedLog = historyList.firstWhereOrNull(
                (log) => log.sessionId == session.id,
              );
              final bool isCompleted = completedLog != null;

              if (isCompleted) {
                return _CompletedSessionCard(
                  session: session,
                  log: completedLog!,
                  onTap: () => _showLogBottomSheet(
                    context,
                    theme,
                    session,
                    completedLog,
                  ),
                );
              } else {
                return _PlannedSessionCard(
                  session: session,
                  theme: theme,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkoutSessionScreen(session: session),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ---------- SECCIÓN CHIPS (se usa en el resumen largo, la dejo por si la quieres reutilizar) ----------
  Widget _buildSectionChips(
    ThemeData theme,
    String title,
    List<WorkoutExercise> exercises,
  ) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    final visible = exercises.take(3).toList();
    final remaining = exercises.length - visible.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...visible.map(
                (e) => Chip(
                  label: Text(e.name),
                  backgroundColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  labelStyle: theme.textTheme.bodySmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (remaining > 0)
                Chip(
                  label: Text('+$remaining más'),
                  backgroundColor:
                      theme.colorScheme.surfaceVariant.withOpacity(0.2),
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- BOTTOM SHEET RESUMEN ----------
  void _showLogBottomSheet(
    BuildContext context,
    ThemeData theme,
    TrainingSession session,
    SessionLog log,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _buildLogSummaryContent(theme, session, log),
          ),
        );
      },
    );
  }

  // ---------- CONTENIDO RESUMEN SESIÓN ----------
  Widget _buildLogSummaryContent(
    ThemeData theme,
    TrainingSession session,
    SessionLog log,
  ) {
    String bestLift = "N/A";

    if (log.loggedExercises.isNotEmpty) {
      final allSets = log.loggedExercises
          .expand((loggedEx) => loggedEx.sets)
          .toList();
      if (allSets.isNotEmpty) {
        final bestSet = allSets.reduce((a, b) => a.weight > b.weight ? a : b);
        bestLift = "${bestSet.weight}kg x ${bestSet.reps} reps";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sesión completada',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dayLabel(session.day),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            _buildSummaryChip(
              theme,
              icon: Icons.speed,
              label: "RPE: ${log.rpe}/10",
            ),
            _buildSummaryChip(
              theme,
              icon: Icons.emoji_events_outlined,
              label: "Mejor set: $bestLift",
            ),
          ],
        ),
        const SizedBox(height: 16),
        if ((log.notes?.isNotEmpty ?? false)) ...[
          Text(
            'Notas de la sesión',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            log.notes!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Desglose de series',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (log.loggedExercises.isEmpty)
          const Text(
            'No se registraron series.',
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          ...log.loggedExercises.map((loggedEx) {
            final exerciseName = session.allExercises
                    .firstWhereOrNull(
                      (ex) => ex.exerciseId == loggedEx.exerciseId,
                    )
                    ?.name ??
                'Ejercicio borrado';

            final sets = loggedEx.sets;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exerciseName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ...sets.map((set) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        top: 2.0,
                      ),
                      child: Text(
                        '• Set ${set.setNumber}: ${set.weight}kg x ${set.reps} reps',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  // ---------- CHIP RESUMEN ----------
  Widget _buildSummaryChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: theme.colorScheme.secondary,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      side: BorderSide(
        color: theme.colorScheme.surfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// Tarjeta de sesión pendiente (planificada)
class _PlannedSessionCard extends StatelessWidget {
  const _PlannedSessionCard({
    required this.session,
    required this.theme,
    required this.onTap,
  });

  final TrainingSession session;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totalExercises = session.allExercises.length;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        ),
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            // Etiqueta día
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.primary.withOpacity(0.12),
              ),
              child: Text(
                _dayShortLabel(session.day),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info sesión
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesión planificada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalExercises ejercicios totales',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (session.trainingExercises.isNotEmpty)
                    Text(
                      'Foco: ${session.trainingExercises.first.name}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Botón play redondo
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 28,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayShortLabel(DayOfWeek d) {
    switch (d) {
      case DayOfWeek.mon:
        return 'Lun';
      case DayOfWeek.tue:
        return 'Mar';
      case DayOfWeek.wed:
        return 'Mié';
      case DayOfWeek.thu:
        return 'Jue';
      case DayOfWeek.fri:
        return 'Vie';
      case DayOfWeek.sat:
        return 'Sáb';
      case DayOfWeek.sun:
        return 'Dom';
    }
  }
}

// Tarjeta sesión completada (resumen corto)
class _CompletedSessionCard extends StatelessWidget {
  const _CompletedSessionCard({
    required this.session,
    required this.log,
    required this.onTap,
  });

  final TrainingSession session;
  final SessionLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primary.withOpacity(0.16),
        ),
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesión completada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RPE ${log.rpe}/10 • toca para ver detalles',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
