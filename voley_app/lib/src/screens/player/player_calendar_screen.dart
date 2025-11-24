import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/providers/calendar_provider.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'package:voley_app/src/screens/player/workout_session_screen.dart';
import 'package:collection/collection.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';

class PlayerCalendarScreen extends ConsumerStatefulWidget {
  const PlayerCalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PlayerCalendarScreenState createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends ConsumerState<PlayerCalendarScreen> {
  // El estado local ahora solo se ocupa de la UI del calendario (días y formato)
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;String _dayLabel(DayOfWeek d) => {
  DayOfWeek.mon:'Lun',
  DayOfWeek.tue:'Mar',
  DayOfWeek.wed:'Mié',
  DayOfWeek.thu:'Jue',
  DayOfWeek.fri:'Vie',
  DayOfWeek.sat:'Sáb',
  DayOfWeek.sun:'Dom',
}[d]!;



  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // --- CAMBIO: _getEventsForDay ahora usa el provider ---
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

    // --- CORRECCIÓN: Iniciar la cadena de dependencias ---
    // 1. Observa primero al usuario.
    final userAsync = ref.watch(currentUserAppUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar usuario: $e')),
      data: (user) {
        // 2. Si no hay usuario, o es un coach, muestra error
        // (ya que esta pantalla es solo para jugadores)
        if (user == null || user.isCoach) {
          return const Center(
            child: Text(
              'Acceso denegado. Esta pantalla es solo para jugadores.',
            ),
          );
        }

        // 3. AHORA que sabemos que hay un jugador, observamos sus providers
        final allProgramsAsync = ref.watch(playerProgramsProvider);
        final selectedProgram = ref.watch(selectedProgramProvider);
        final events = ref.watch(calendarEventsProvider);

        // 4. Construye la UI del calendario
        return allProgramsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error al cargar programa: $e')),
          data: (programs) {
            // --- CAMBIO: Toda la lógica de sincronización ha sido ELIMINADA ---
            // (Ahora vive en el 'selectedProgramProvider')

            // CASO 1: No hay programas (o el provider de selección aún no se inicializa).
            // El 'selectedProgramProvider' se pondrá 'null' automáticamente.
            if (selectedProgram == null) {
              return _buildNoProgramWidget(theme);
            }

            // --- ESTADO PRINCIPAL (READY) ---
            // Si llegamos aquí, 'programs' no está vacío y 'selectedProgram' es válido.

            return Column(
              children: [
                // El selector ahora lee y escribe en el provider
                _buildProgramSelector(theme, programs, selectedProgram),

                TableCalendar<TrainingSession>(
                  firstDay: selectedProgram.startDate.subtract(
                    const Duration(days: 30),
                  ),
                  lastDay: selectedProgram.endDate.add(
                    const Duration(days: 30),
                  ),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mes',
                    CalendarFormat.week: 'Semana',
                  },
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                  // El eventLoader ahora consume el provider 'events'
                  eventLoader: (day) => _getEventsForDay(day, events),

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
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
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                    ),
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                    weekendTextStyle: TextStyle(
                      color: theme.colorScheme.secondary,
                    ),
                    outsideTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ref
                      .watch(sessionLogHistoryProvider)
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(
                          child: Text('Error al cargar historial: $e'),
                        ),
                        data: (historyList) {
                          // Obtenemos los eventos para el día seleccionado desde el provider 'events'
                          final normalizedDay = _selectedDay != null
                              ? DateTime(
                                  _selectedDay!.year,
                                  _selectedDay!.month,
                                  _selectedDay!.day,
                                )
                              : null;
                          final selectedEvents =
                              (normalizedDay != null &&
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
    );
  }

  /// Widget para mostrar cuando no hay programas
  Widget _buildNoProgramWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: theme.colorScheme.secondary, // Azul Pro
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes un programa activo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Habla con tu entrenador para que te asigne un plan de entrenamiento.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// El selector ahora lee y escribe en el [selectedProgramProvider]
  Widget _buildProgramSelector(
    ThemeData theme,
    List<Program> programs,
    Program currentSelectedProgram,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      color: theme.colorScheme.surface.withOpacity(0.5),
      child: DropdownButtonFormField<Program>(
        value:
            currentSelectedProgram, // viene del ref.watch(selectedProgramProvider)
        items: programs.map((program) {
          return DropdownMenuItem<Program>(
            value: program,
            child: Text(program.title, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (Program? newProgram) {
          if (newProgram != null) {
            // ✅ Con StateProvider asignas directamente el estado:
            ref.read(selectedProgramProvider.notifier).state = newProgram;

            // Reset UI local del calendario (igual que antes)
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
          labelText: 'Programa Seleccionado',
          filled: true,
          fillColor: theme.colorScheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 12.0,
          ),
        ),
      ),
    );
  }

  /// La lista de eventos ahora recibe los eventos como parámetro.
  Widget _buildEventList(
    BuildContext context,
    ThemeData theme,
    List<SessionLog> historyList,
    List<TrainingSession> selectedEvents,
  ) {
    if (_selectedDay == null) return const SizedBox.shrink();

    if (selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.coffee_outlined,
              size: 60,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'Día de Descanso',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final session = selectedEvents[index];

        final SessionLog? completedLog = historyList.firstWhereOrNull(
          (log) => log.sessionId == session.id,
        );
        final bool isCompleted = completedLog != null;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCompleted
                  ? theme
                        .colorScheme
                        .primary // Borde Volt
                  : theme.colorScheme.secondary.withOpacity(
                      0.5,
                    ), // Borde Azul Pro
              width: 1.5,
            ),
          ),
          color: isCompleted
              ? theme.colorScheme.primary.withOpacity(0.1) // Fondo Volt
              : theme.colorScheme.surfaceVariant.withOpacity(
                  0.6,
                ), // Fondo oscuro

          child: isCompleted
              ? _buildLogSummary(theme, session, completedLog!) // Añadido !
              : _buildPlannedSession(context, theme, session),
        );
      },
    );
  }

  /// Sin cambios
  Widget _buildPlannedSession(
    BuildContext context,
    ThemeData theme,
    TrainingSession session,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSessionScreen(session: session),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
  _dayLabel(session.day),
  style: theme.textTheme.titleSmall?.copyWith(
    color: theme.colorScheme.secondary,
    fontWeight: FontWeight.bold,
  ),
),

                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: session.allExercises
                        .map(
                          (e) => Chip(
                            label: Text(e.name),
                            backgroundColor: theme.colorScheme.surface,
                            labelStyle: theme.textTheme.bodySmall,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary, // Volt
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 60,
                color: theme.colorScheme.onPrimary, // Oscuro
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sin cambios
  Widget _buildLogSummary(
    ThemeData theme,
    TrainingSession session,
    SessionLog log,
  ) {
    String bestLift = "N/A";

    // --- CAMBIO: Lógica para List<LoggedExercise> ---
    if (log.loggedExercises.isNotEmpty) {
      final allSets = log.loggedExercises
          .expand((loggedEx) => loggedEx.sets)
          .toList();
      if (allSets.isNotEmpty) {
        final bestSet = allSets.reduce((a, b) => a.weight > b.weight ? a : b);
        bestLift = "${bestSet.weight}kg x ${bestSet.reps} reps";
      }
    }
    // --- FIN DEL CAMBIO ---

    return ExpansionTile(
      title: Text(
        '${session.day} - COMPLETADO',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary, // Volt
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Wrap(
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
              label: "Mejor Set: $bestLift",
            ),
          ],
        ),
      ),
      trailing: Icon(
        Icons.expand_more,
        color: theme.colorScheme.primary.withOpacity(0.7),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((log.notes?.isNotEmpty ?? false)) ...[
                const Divider(height: 16),
                Text('Notas de la Sesión:', style: theme.textTheme.bodySmall),
                Text(
                  log.notes!, // seguro porque lo chequeamos arriba
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,

                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 16),
              ] else ...[
                const Divider(height: 16),
              ],
              Text(
                'Desglose de Series',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // --- CAMBIO: Iterar sobre List<LoggedExercise> ---
              if (log.loggedExercises.isEmpty)
                const Text(
                  'No se registraron series.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                ...log.loggedExercises.map((loggedEx) {
                  // Encuentra el nombre del ejercicio original
                  final exerciseName =
                      session.allExercises
                          .firstWhereOrNull(
                            (ex) => ex.exerciseId == loggedEx.exerciseId,
                          )
                          ?.name ??
                      'Ejercicio Borrado';

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
                              left: 16.0,
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
          ),
        ),
      ],
    );
  }

  /// Sin cambios
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
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.surfaceVariant),
    );
  }
}
