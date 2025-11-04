import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/providers/providers.dart'; // Para explorerProgramsProvider
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';

/// Provider que almacena qué programa está seleccionado actualmente en la UI.
/// Usamos StateProvider porque la UI (el Dropdown) necesita modificarlo.
final selectedProgramProvider = StateProvider<Program?>((ref) => null);

/// Provider que calcula el mapa de eventos (LinkedHashMap) para el calendario.
///
/// Observa el [selectedProgramProvider]. Si el programa seleccionado cambia,
/// este provider se recalculará automáticamente y entregará el nuevo mapa de eventos.
final calendarEventsProvider =
    Provider<LinkedHashMap<DateTime, List<TrainingSession>>>((ref) {
  // Observa el programa que está seleccionado actualmente.
  final selectedProgram = ref.watch(selectedProgramProvider);

  // Si no hay ningún programa seleccionado, devuelve un mapa vacío.
  if (selectedProgram == null) {
    return LinkedHashMap();
  }

  // Si hay un programa, construye el mapa de eventos para él.
  return _buildEventMap(selectedProgram);
});

// --- LÓGICA DE NEGOCIO EXTRAÍDA DE LA VISTA ---

/// Construye el mapa de eventos a partir de un programa dado.
/// Esta es la misma función que tenías, ahora aislada.
LinkedHashMap<DateTime, List<TrainingSession>> _buildEventMap(
  Program program,
) {
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
      final normalizedDate = DateTime(
        dateForDay.year,
        dateForDay.month,
        dateForDay.day,
      );

      final sessionsForDay = micro.sessions
          .where((s) => s.day.toLowerCase() == dayString)
          .toList();

      if (sessionsForDay.isNotEmpty) {
        if (newEvents[normalizedDate] == null) {
          newEvents[normalizedDate] = [];
        }
        newEvents[normalizedDate]!.addAll(sessionsForDay);
      }
    }
    currentDate = currentDate.add(const Duration(days: 7));
  }
  return newEvents;
}

/// Función de utilidad (la misma que tenías).
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
