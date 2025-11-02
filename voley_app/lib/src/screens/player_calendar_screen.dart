// lib/src/screens/player_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/providers/providers.dart'; 
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'dart:collection';
import 'package:voley_app/src/screens/workout_session_screen.dart';

class PlayerCalendarScreen extends ConsumerStatefulWidget {
  const PlayerCalendarScreen({Key? key}) : super(key: key);

  @override
  _PlayerCalendarScreenState createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends ConsumerState<PlayerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  LinkedHashMap<DateTime, List<TrainingSession>> _events = LinkedHashMap();

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
      case 1: return 'lunes';
      case 2: return 'martes';
      case 3: return 'miércoles';
      case 4: return 'jueves';
      case 5: return 'viernes';
      case 6: return 'sábado';
      case 7: return 'domingo';
      default: return '';
    }
  }

  /// Esta función construye y devuelve el mapa.
  LinkedHashMap<DateTime, List<TrainingSession>> _buildEventMap(Program program) {
    final newEvents = LinkedHashMap<DateTime, List<TrainingSession>>(
      equals: isSameDay,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );

    final allMicrocycles =
        program.mesocycles.expand((m) => m.microcycles).toList();
    DateTime currentDate = program.startDate;

    for (int weekIndex = 0; weekIndex < allMicrocycles.length; weekIndex++) {
      final micro = allMicrocycles[weekIndex];
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dateForDay = currentDate.add(Duration(days: dayIndex));
        final dayString = _mapWeekdayToString(dateForDay.weekday);

        final normalizedDate =
            DateTime(dateForDay.year, dateForDay.month, dateForDay.day);

        final session = micro.sessions.firstWhere(
          (s) => s.day.toLowerCase() == dayString,
          orElse: () => TrainingSession(
              day: '', objective: 'Descanso', load: 0, exercises: []),
        );

        if (session.objective != 'Descanso') {
          if (newEvents[normalizedDate] == null) {
            newEvents[normalizedDate] = [];
          }
          newEvents[normalizedDate]!.add(session);
        }
      }
      currentDate = currentDate.add(const Duration(days: 7));
    }
    return newEvents;
  }

  /// Devuelve la lista de sesiones para un día específico
  List<TrainingSession> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Asumiendo que 'playerProgramProvider' está en 'providers.dart'
    // y es el StreamProvider<Program?> correcto para el jugador logueado.
    final programAsync = ref.watch(playerProgramProvider);

    // Escucha el provider
    ref.listen<AsyncValue<Program?>>(playerProgramProvider, (previous, next) {
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

    // --- ¡ERROR 1 CORREGIDO! ---
    // Se ha eliminado el Scaffold y el AppBar.
    // Esta pantalla es solo el 'body' de la pestaña.
    return programAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error al cargar programa: $e')),
      data: (program) {
        if (program == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Aún no tienes un programa asignado.\nPídele a tu entrenador que te genere uno.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
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
              calendarFormat: CalendarFormat.month,
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
            const Divider(),
            Expanded(
              // --- ¡ERROR 2 CORREGIDO! ---
              // La llamada ya no necesita parámetros
              child: _buildEventList(),
            ),
          ],
        );
      },
    );
  }

  /// Lista de eventos interactiva
  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final selectedEvents = _getEventsForDay(_selectedDay!);

    if (selectedEvents.isEmpty) {
      return const Center(
        child: Text('Día de Descanso', style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final session = selectedEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.day} - ${session.objective}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),
                ...session.exercises.map((e) => ListTile(
                      dense: true,
                      title: Text(e.name),
                      subtitle: Text('${e.sets}x${e.reps} @ ${e.intensity}'),
                    )),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Empezar Sesión'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutSessionScreen(session: session),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}