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
import 'package:voley_app/src/widgets/today_session_hero_card.dart';
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
    final historyAsync = ref.watch(sessionLogHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi entrenamiento'), centerTitle: true),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
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

                return historyAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                      Center(child: Text('Error al cargar historial: $e')),
                  data: (historyList) {
                    final normalizedDay = _selectedDay != null
                        ? DateTime(
                            _selectedDay!.year,
                            _selectedDay!.month,
                            _selectedDay!.day,
                          )
                        : null;

                    final selectedDate = normalizedDay ?? DateTime.now();

                    final selectedEvents = _getEventsForDay(
                      selectedDate,
                      events,
                    );

                    final selectedLog = selectedEvents.isNotEmpty
                        ? historyList.firstWhereOrNull(
                            (log) => log.sessionId == selectedEvents.first.id,
                          )
                        : null;

                    final isTodaySelected = isSameDay(
                      selectedDate,
                      DateTime.now(),
                    );

                    return Column(
                      children: [
                        _buildTopBar(theme, programs, selectedProgram),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: TodaySessionHeroCard(
                                    key: ValueKey(
                                      selectedDate.toIso8601String(),
                                    ),
                                    date: selectedDate,
                                    session: selectedEvents.isNotEmpty
                                        ? selectedEvents.first
                                        : null,
                                    completedLog: selectedLog,
                                    onStart: selectedEvents.isNotEmpty
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    WorkoutSessionScreen(
                                                      session:
                                                          selectedEvents.first,
                                                    ),
                                              ),
                                            );
                                          }
                                        : null,
                                    onViewLog:
                                        selectedEvents.isNotEmpty &&
                                            selectedLog != null
                                        ? () => _showLogBottomSheet(
                                            context,
                                            theme,
                                            selectedEvents.first,
                                            selectedLog,
                                          )
                                        : null,
                                    isToday: isTodaySelected,
                                    sessionVisuals: selectedEvents.isNotEmpty
                                        ? _resolveSessionVisuals(
                                            selectedEvents.first,
                                            theme,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _GoToTodayButton(
                                isTodaySelected: isTodaySelected,
                                onTap: () {
                                  final now = DateTime.now();
                                  setState(() {
                                    _focusedDay = now;
                                    _selectedDay = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildWeekCalendar(
                            theme,
                            selectedProgram,
                            events,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.4,
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: _buildEventList(
                              context,
                              theme,
                              historyList,
                              selectedEvents,
                              selectedDate,
                              key: ValueKey(
                                'event-list-${selectedDate.toIso8601String()}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
                  child: Text(program.title, overflow: TextOverflow.ellipsis),
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
      availableCalendarFormats: const {CalendarFormat.week: 'Semana'},
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
        defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
        weekendTextStyle: TextStyle(color: theme.colorScheme.secondary),
        outsideTextStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.35),
        ),
      ),
    );
  }

  SessionVisuals _resolveSessionVisuals(
    TrainingSession session,
    ThemeData theme,
  ) {
    final allExercises = session.trainingExercises.isNotEmpty
        ? session.trainingExercises
        : (session.allExercises);

    final firstName = allExercises.isNotEmpty
        ? allExercises.first.name.toLowerCase()
        : '';

    if (firstName.contains('movil')) {
      return SessionVisuals(
        icon: Icons.self_improvement_rounded,
        color: theme.colorScheme.secondary,
        label: 'Movilidad',
      );
    }

    if (firstName.contains('cond') || firstName.contains('cardio')) {
      return SessionVisuals(
        icon: Icons.directions_run_rounded,
        color: theme.colorScheme.tertiary,
        label: 'Acondicionamiento',
      );
    }

    if (firstName.contains('potencia') || firstName.contains('plyo')) {
      return SessionVisuals(
        icon: Icons.bolt_rounded,
        color: theme.colorScheme.secondary,
        label: 'Potencia',
      );
    }

    return SessionVisuals(
      icon: Icons.fitness_center_rounded,
      color: theme.colorScheme.primary,
      label: 'Fuerza',
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
    DateTime selectedDate,
    {Key? key}
  ) {
    // Día sin sesiones
    if (selectedEvents.isEmpty) {
      return KeyedSubtree(
        key: key,
        child: Center(
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
        ),
      );
    }

    // Hay al menos una sesión: mostramos un pequeño resumen + lista
    final bool anyCompletedForDay = selectedEvents.any((session) {
      return historyList.any((log) => log.sessionId == session.id);
    });

    final selectedDateLabel =
        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}';

    final isToday = isSameDay(selectedDate, DateTime.now());

    final sessionVisuals = _resolveSessionVisuals(selectedEvents.first, theme);

    final statusLabel = anyCompletedForDay
        ? 'Sesión completada'
        : 'Sesión planificada';

    final statusIcon = anyCompletedForDay
        ? Icons.check_circle_rounded
        : Icons.flash_on;

    final statusColor = anyCompletedForDay
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          // Resumen del día seleccionado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? theme.colorScheme.primary.withOpacity(0.6)
                      : Colors.transparent,
                ),
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
                          isToday
                              ? 'Hoy • $selectedDateLabel'
                              : 'Día $selectedDateLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sessionVisuals.label} • $statusLabel',
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
              final visuals = _resolveSessionVisuals(session, theme);

              final SessionLog? completedLog = historyList.firstWhereOrNull(
                (log) => log.sessionId == session.id,
              );
              final bool isCompleted = completedLog != null;

              if (isCompleted) {
                return _CompletedSessionCard(
                  session: session,
                  visuals: visuals,
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
                  visuals: visuals,
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
    ));
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
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                    0.4,
                  ),
                  labelStyle: theme.textTheme.bodySmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (remaining > 0)
                Chip(
                  label: Text('+$remaining más'),
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(
                    0.2,
                  ),
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
            final exerciseName =
                session.allExercises
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
                      padding: const EdgeInsets.only(left: 12.0, top: 2.0),
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
      avatar: Icon(icon, size: 16, color: theme.colorScheme.secondary),
      label: Text(label),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      side: BorderSide(color: theme.colorScheme.surfaceVariant),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _GoToTodayButton extends StatelessWidget {
  const _GoToTodayButton({required this.isTodaySelected, required this.onTap});

  final bool isTodaySelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: isTodaySelected ? null : onTap,
          icon: const Icon(Icons.calendar_today_rounded),
          tooltip: 'Ir a hoy',
          style: IconButton.styleFrom(
            backgroundColor: isTodaySelected
                ? theme.colorScheme.surfaceVariant
                : theme.colorScheme.primary.withOpacity(0.15),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ir a hoy',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// Tarjeta de sesión pendiente (planificada)
class _PlannedSessionCard extends StatefulWidget {
  const _PlannedSessionCard({
    required this.session,
    required this.theme,
    required this.visuals,
    required this.onTap,
  });

  final TrainingSession session;
  final ThemeData theme;
  final SessionVisuals visuals;
  final VoidCallback onTap;

  @override
  State<_PlannedSessionCard> createState() => _PlannedSessionCardState();
}

class _PlannedSessionCardState extends State<_PlannedSessionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() {
        _pressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExercises = widget.session.allExercises.length;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Material(
        color: widget.theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: widget.visuals.color.withOpacity(0.14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.visuals.icon,
                        size: 18,
                        color: widget.visuals.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _dayShortLabel(widget.session.day),
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.visuals.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.visuals.label,
                        style: widget.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalExercises ejercicios totales',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (widget.session.trainingExercises.isNotEmpty)
                        Text(
                          'Foco: ${widget.session.trainingExercises.first.name}',
                          style: widget.theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: widget.theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 28,
                    color: widget.theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
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
class _CompletedSessionCard extends StatefulWidget {
  const _CompletedSessionCard({
    required this.session,
    required this.visuals,
    required this.log,
    required this.onTap,
  });

  final TrainingSession session;
  final SessionVisuals visuals;
  final SessionLog log;
  final VoidCallback onTap;

  @override
  State<_CompletedSessionCard> createState() => _CompletedSessionCardState();
}

class _CompletedSessionCardState extends State<_CompletedSessionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() {
        _pressed = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Material(
        color: theme.colorScheme.primary.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Icon(
                  widget.visuals.icon,
                  color: widget.visuals.color,
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
                        'RPE ${widget.log.rpe}/10 • toca para ver detalles',
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
        ),
      ),
    );
  }
}
