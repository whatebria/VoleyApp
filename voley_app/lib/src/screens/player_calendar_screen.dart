// lib/src/screens/player_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'dart:collection';
import 'package:voley_app/providers/auth_provider.dart';

class PlayerCalendarScreen extends ConsumerStatefulWidget {
  const PlayerCalendarScreen({Key? key}) : super(key: key);

  @override
  _PlayerCalendarScreenState createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends ConsumerState<PlayerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Mapa para almacenar los eventos (sesiones) cacheados
  LinkedHashMap<DateTime, List<TrainingSession>> _events = LinkedHashMap();

  // Mapea el weekday de DateTime (Lunes=1...Domingo=7) a tus Strings
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

  /// Carga y mapea todas las sesiones del programa a un mapa de eventos
  void _cacheProgramEvents(Program? program) {
    _events.clear();
    if (program == null) return;

    final allMicrocycles = program.mesocycles.expand((m) => m.microcycles).toList();
    DateTime currentDate = program.startDate;

    for (int weekIndex = 0; weekIndex < allMicrocycles.length; weekIndex++) {
      final micro = allMicrocycles[weekIndex];
      // Itera 7 días para esta semana
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dateForDay = currentDate.add(Duration(days: dayIndex));
        final dayString = _mapWeekdayToString(dateForDay.weekday);
        
        // Normaliza la fecha a medianoche (para que coincida con el 'day' del calendario)
        final normalizedDate = DateTime(dateForDay.year, dateForDay.month, dateForDay.day);

        // Busca si hay una sesión para ese día
        final session = micro.sessions.firstWhere(
          (s) => s.day.toLowerCase() == dayString,
          orElse: () => TrainingSession(day: '', objective: 'Descanso', load: 0, exercises: []), // Retorna un objeto 'Descanso'
        );

        if (session.objective != 'Descanso') {
          _events[normalizedDate] = [session];
        }
      }
      currentDate = currentDate.add(const Duration(days: 7));
    }
    // Selecciona el día de hoy al cargar
    setState(() {
      _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    });
  }

  /// Devuelve la lista de sesiones para un día específico
  List<TrainingSession> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(generatedProgramProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Programa'),
        // (Añade un botón de logout si lo deseas)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).logout();
              // (La navegación al login se manejará automáticamente por el AuthWrapper)
            },
          )
        ],
      ),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error al cargar programa: $e')),
        data: (program) {
          if (program == null) {
            return const Center(
              child: Text(
                'Aún no tienes un programa asignado.\nPídele a tu entrenador que te genere uno.',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Si el mapa de eventos está vacío, cárgalo
          if (_events.isEmpty) {
            _cacheProgramEvents(program);
          }

          return Column(
            children: [
              TableCalendar<TrainingSession>(
                firstDay: program.startDate.subtract(const Duration(days: 30)),
                lastDay: program.endDate.add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                locale: 'es_ES', // (Asegúrate de tener 'flutter_localizations' si quieres esto)
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay, // ¡Aquí se cargan los marcadores!
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay; // Actualiza el foco
                  });
                },
                calendarStyle: const CalendarStyle(
                  // Estilo para los marcadores de eventos
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              const Divider(),
              Expanded(
                child: _buildEventList(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construye la lista de sesiones para el día seleccionado
  Widget _buildEventList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final selectedEvents = _getEventsForDay(_selectedDay!);

    if (selectedEvents.isEmpty) {
      return const Center(
        child: Text('Día de Descanso', style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final session = selectedEvents[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.day} - Objetivo: ${session.objective}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Carga: ${session.load}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const Divider(height: 20),
                  const Text('Ejercicios:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...session.exercises.map((ex) => ListTile(
                        title: Text(ex.name),
                        subtitle: Text('${ex.sets}x${ex.reps} @ ${ex.intensity}'),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}