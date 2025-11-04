// lib/src/screens/player_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/src/models/program/session_log.dart';
import 'dart:collection';
import 'package:voley_app/src/screens/player/workout_session_screen.dart';
import 'package:collection/collection.dart';

class PlayerCalendarScreen extends ConsumerStatefulWidget {
  const PlayerCalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PlayerCalendarScreenState createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends ConsumerState<PlayerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  LinkedHashMap<DateTime, List<TrainingSession>> _events = LinkedHashMap();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  String _mapWeekdayToString(int weekday) {
    switch (weekday) {
      case 1:
        return 'lunes';
      case 2:
        return 'martes';
      case 3:
        return 'miércoles';
      case 4:
        return 'jueves';
      case 5:
        return 'viernes';
      case 6:
        return 'sábado';
      case 7:
        return 'domingo';
      default:
        return '';
    }
  }

  LinkedHashMap<DateTime, List<TrainingSession>> _buildEventMap(
    Program program,
  ) {
    final newEvents = LinkedHashMap<DateTime, List<TrainingSession>>(
      equals: isSameDay,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );
    final allMicrocycles = program.mesocycles
        .expand((m) => m.microcycles)
        .toList();
    DateTime currentDate = program.startDate;

    for (int weekIndex = 0; weekIndex < allMicrocycles.length; weekIndex++) {
      final micro = allMicrocycles[weekIndex];
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dateForDay = currentDate.add(Duration(days: dayIndex));
        final dayString = _mapWeekdayToString(dateForDay.weekday);
        final normalizedDate = DateTime(
          dateForDay.year,
          dateForDay.month,
          dateForDay.day,
        );
        final session = micro.sessions.firstWhere(
          (s) => s.day.toLowerCase() == dayString,
          orElse: () => TrainingSession(
            day: '',
            load: 0,
            exercises: [], id: '',
          ),
        );
      }
      currentDate = currentDate.add(const Duration(days: 7));
    }
    return newEvents;
  }

  List<TrainingSession> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Observa el provider del programa (que depende del perfil)
    final programAsync = ref.watch(generatedProgramProvider); 

    ref.listen<AsyncValue<Program?>>(generatedProgramProvider, (previous, next) {
      final program = next.value;
      if (program != null) {
        setState(() {
          _events = _buildEventMap(program);
          _selectedDay =
              DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
        });
      } else {
        setState(() => _events.clear());
      }
    });

    // --- MEJORA: Se eliminó el Scaffold y el AppBar ---
    return programAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar programa: $e')),
      data: (program) {
        if (program == null) {
          // --- MEJORA DE UX: Empty State con tu tema ---
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
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

        // El programa existe, construye la UI
        return Column(
          children: [
            TableCalendar<TrainingSession>(
              firstDay: program.startDate.subtract(const Duration(days: 30)),
              lastDay: program.endDate.add(const Duration(days: 30)),
              focusedDay: _focusedDay,

              calendarFormat: _calendarFormat, // Usa la variable de estado
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format; // Actualiza el estado al tocar el botón
                });
              },// Inicia en formato semana
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.week: 'Semana',
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
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
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                formatButtonTextStyle:
                    TextStyle(color: theme.colorScheme.onSurface),
                leftChevronIcon: Icon(Icons.chevron_left,
                    color: theme.colorScheme.onSurface),
                rightChevronIcon: Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle:
                    TextStyle(color: theme.colorScheme.onPrimary),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle:
                    TextStyle(color: theme.colorScheme.onSurface),
                weekendTextStyle:
                    TextStyle(color: theme.colorScheme.secondary),
                outsideTextStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
            ),
            const Divider(height: 1, thickness: 1),
            
            Expanded(
              child: ref.watch(sessionLogHistoryProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error al cargar historial: $e')),
                    data: (historyList) => _buildEventList(context, theme, historyList),
                  ),
            ),
          ],
        );
      },
    );
  }

  /// --- MEJORA DE UX: Lista de eventos rediseñada ---
Widget _buildEventList(BuildContext context, ThemeData theme, List<SessionLog> historyList) {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final selectedEvents = _getEventsForDay(_selectedDay!);

    if (selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee_outlined, size: 60, color: theme.textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text(
              'Día de Descanso',
              style: theme.textTheme.titleLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
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
                  ? theme.colorScheme.primary // Borde Volt
                  : theme.colorScheme.secondary.withOpacity(0.5), // Borde Azul Pro
              width: 1.5,
            ),
          ),
          color: isCompleted
              ? theme.colorScheme.primary.withOpacity(0.1) // Fondo Volt
              : theme.colorScheme.surfaceVariant.withOpacity(0.6), // Fondo oscuro
          
          // --- MEJORA: La tarjeta "Completada" ahora es un ExpansionTile ---
          // La tarjeta "Pendiente" sigue siendo un InkWell
          child: isCompleted
              ? _buildLogSummary(theme, session, completedLog) // Tarjeta de Resumen EXPANDIBLE
              : _buildPlannedSession(context, theme, session), // Tarjeta de Acción
        );
      },
    );
  }
  /// --- MEJORA DE UX: Widget para "Pendiente" (más amigable y accionable) ---
  Widget _buildPlannedSession(BuildContext context, ThemeData theme, TrainingSession session) {
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
                    session.day,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: session.exercises.map((e) => Chip(
                      label: Text(e.name),
                      backgroundColor: theme.colorScheme.surface,
                      labelStyle: theme.textTheme.bodySmall,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // --- El "Llamado a la Acción" (CTA) ---
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary, // Volt
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 60,
                color: theme.colorScheme.onPrimary, // Oscuro
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLogSummary(ThemeData theme, TrainingSession session, SessionLog log) {
    String bestLift = "N/A";
    if (log.exercises.isNotEmpty) {
      final allSets = log.exercises.values.expand((sets) => sets).toList();
      if (allSets.isNotEmpty) {
        final bestSet = allSets.reduce((a, b) => a.weight > b.weight ? a : b);
        bestLift = "${bestSet.weight}kg x ${bestSet.reps} reps";
      }
    }

    // --- MEJORA: Convertido en ExpansionTile ---
    return ExpansionTile(
      // --- Encabezado Plegado (lo que ves primero) ---
      title: Text(
        '${session.day} - COMPLETADO',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary, // Volt
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        // --- SOLUCIÓN AL OVERFLOW: Row -> Wrap ---
        child: Wrap(
          spacing: 8.0, // Espacio horizontal
          runSpacing: 4.0, // Espacio vertical si se envuelve
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
      // --- Contenido Expandido (El desglose) ---
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Notas ---
              if (log.notes.isNotEmpty) ...[
                const Divider(height: 16),
                Text('Notas de la Sesión:', style: theme.textTheme.bodySmall),
                Text(
                  log.notes,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 16),
              ] else ... [
                const Divider(height: 16),
              ],
              
              // --- Título del Desglose ---
              Text(
                'Desglose de Series',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // --- Lógica del Desglose ---
              if (log.exercises.isEmpty)
                const Text('No se registraron series.', style: TextStyle(fontStyle: FontStyle.italic))
              else
                ...log.exercises.entries.map((entry) {
                  final String exerciseId = entry.key;
                  final List<SetLog> sets = entry.value;

                  final exerciseName = session.exercises
                      .firstWhereOrNull((ex) => ex.exerciseId == exerciseId)
                      ?.name ?? 'Ejercicio Borrado';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseName,
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        ...sets.map((set) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 2.0),
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

  /// Helper para los chips de resumen (sin cambios)
  Widget _buildSummaryChip(ThemeData theme, {required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.secondary),
      label: Text(label),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600
      ),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.surfaceVariant),
    );
  }
}