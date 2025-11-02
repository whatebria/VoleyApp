// lib/src/screens/player_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/providers/auth_provider.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'dart:collection'; // Para LinkedHashMap

// --- MEJORA 2: Provider de estado de logout (debe ser global o importado) ---
// Asumo que este provider ya existe, como en HomeScreen.
// final isLoggingOutProvider = StateProvider<bool>((ref) => false);

class PlayerCalendarScreen extends ConsumerStatefulWidget {
  const PlayerCalendarScreen({Key? key}) : super(key: key);

  @override
  _PlayerCalendarScreenState createState() => _PlayerCalendarScreenState();
}

class _PlayerCalendarScreenState extends ConsumerState<PlayerCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Mapa para almacenar los eventos (sesiones) cacheados
  // Tu lógica para esto es excelente.
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

  /// Esta función construye y devuelve el mapa.
  LinkedHashMap<DateTime, List<TrainingSession>> _buildEventMap(Program program) {
    final newEvents = LinkedHashMap<DateTime, List<TrainingSession>>(
      equals: isSameDay,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );
    
    final allMicrocycles = program.mesocycles.expand((m) => m.microcycles).toList();
    DateTime currentDate = program.startDate;

    for (int weekIndex = 0; weekIndex < allMicrocycles.length; weekIndex++) {
      final micro = allMicrocycles[weekIndex];
      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dateForDay = currentDate.add(Duration(days: dayIndex));
        final dayString = _mapWeekdayToString(dateForDay.weekday);
        
        final normalizedDate = DateTime(dateForDay.year, dateForDay.month, dateForDay.day);

        // Busca si hay una sesión para ese día
        final session = micro.sessions.firstWhere(
          (s) => s.day.toLowerCase() == dayString,
          orElse: () => TrainingSession(day: '', objective: 'Descanso', load: 0, exercises: []),
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
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    ref.read(isLoggingOutProvider.notifier).state = true;
    try {
      await ref.read(authServiceProvider).logout();
    } catch (e) {
      ref.read(isLoggingOutProvider.notifier).state = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- MEJORA 1: Obtener el tema ---
    final theme = Theme.of(context);
    
    // Asumo que este provider existe y es el correcto para el jugador
    final programAsync = ref.watch(generatedProgramProvider); 
    // --- MEJORA 2: Observar estado de logout ---
    final isLoggingOut = ref.watch(isLoggingOutProvider);

    // Tu lógica de 'ref.listen' aquí es perfecta.
    // Reacciona al cambio de programa y actualiza el estado local.
    ref.listen<AsyncValue<Program?>>(generatedProgramProvider, (previous, next) {
      final program = next.value;
      if (program != null) {
        setState(() {
          _events = _buildEventMap(program);
          _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Programa'),
        actions: [
          // --- MEJORA 2: Botón de logout con estado ---
          IconButton(
            icon: isLoggingOut
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.logout),
            onPressed: isLoggingOut ? null : () => _handleLogout(context, ref),
          )
        ],
      ),
      body: programAsync.when(
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

          return Column(
            children: [
              // --- MEJORA 1: Calendario con tema "Volt Pro" ---
              TableCalendar<TrainingSession>(
                firstDay: program.startDate.subtract(const Duration(days: 30)),
                lastDay: program.endDate.add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                // locale: 'es_ES',
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                
                // --- INICIO DE ESTILOS "VOLT PRO" ---
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                  leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
                  rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                ),
                calendarStyle: CalendarStyle(
                  // Marcador de "Hoy"
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: theme.colorScheme.onPrimary),

                  // Marcador de "Seleccionado"
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary, // Color Volt
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary), // Texto negro

                  // Marcador de Evento (el punto)
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary, // Color Azul Pro
                    shape: BoxShape.circle,
                  ),
                  
                  // Estilos de texto
                  defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                  weekendTextStyle: TextStyle(color: theme.colorScheme.secondary), // Fines de semana en Azul Pro
                  outsideTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
                // --- FIN DE ESTILOS ---
              ),
              const Divider(),
              Expanded(
                child: _buildEventList(theme),
              ),
            ],
          );
        },
      ),
    );
  }

  /// --- MEJORA 3: Lista de eventos con tema y mejor layout ---
  Widget _buildEventList(ThemeData theme) {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final selectedEvents = _getEventsForDay(_selectedDay!);

    if (selectedEvents.isEmpty) {
      return Center(
        child: Text(
          'Día de Descanso',
          style: theme.textTheme.titleLarge?.copyWith(color: theme.textTheme.bodySmall?.color),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final s = selectedEvents[index];
        // Usamos un ListTile dentro del Card para mejor estructura
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          elevation: 0,
          child: ExpansionTile(
            // --- NUEVO LAYOUT ---
            leading: Icon(
              Icons.fitness_center,
              color: theme.colorScheme.primary, // Volt
              size: 36,
            ),
            title: Text(
              s.day, // Título: "Lunes"
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              s.objective, // Subtítulo: "Fuerza Máxima"
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            // --- FIN NUEVO LAYOUT ---
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carga: ${s.load}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Divider(height: 20),
                    Text(
                      'Ejercicios:',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...s.exercises.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.primary, // Volt
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${e.name} (${e.sets}x${e.reps} @ ${e.intensity})',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}