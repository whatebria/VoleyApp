import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/providers/providers.dart'; // Para playerProgramsProvider

// --- CAMBIO: Convertido de StateProvider a NotifierProvider ---

/// Este Notifier gestiona QUÉ programa está seleccionado actualmente.
///
/// Observa la lista de programas del jugador (`playerProgramsProvider`)
/// y se actualiza automáticamente para asegurarse de que la selección
/// sea siempre válida.
class SelectedProgramNotifier extends Notifier<Program?> {
  Program? _lastSelected; // cache local

  @override
  Program? build() {
    final programsAsync = ref.watch(playerProgramsProvider);

    return programsAsync.when(
      loading: () => _lastSelected, // conserva lo anterior (o null)
      error: (e, s) => _lastSelected, // no cambies nada en error
      data: (programs) {
        if (programs.isEmpty) {
          if (_lastSelected == null ||
              !programs.any((p) => p.id == _lastSelected!.id)) {
            _lastSelected = programs.first;
          }
          return null;
        }
        if (_lastSelected == null || !programs.contains(_lastSelected)) {
          _lastSelected = programs.first; // default estable
        }
        return _lastSelected;
      },
    );
  }

  void selectProgram(Program newProgram) {
    _lastSelected = newProgram; // actualiza cache
    state = newProgram; // publica nuevo estado
  }
}

final selectedProgramProvider = StateProvider<Program?>((ref) => null);

// --- 2. Provider de Eventos del Calendario (sin cambios) ---

/// Este provider depende del programa seleccionado y calcula
/// el mapa de eventos para `TableCalendar`.
final calendarEventsProvider =
    Provider<LinkedHashMap<DateTime, List<TrainingSession>>>((ref) {
      final selectedProgram = ref.watch(selectedProgramProvider);

      // Si no hay programa seleccionado, devuelve un mapa vacío
      if (selectedProgram == null) {
        return LinkedHashMap<DateTime, List<TrainingSession>>();
      }

      // Si hay un programa, construye el mapa de eventos
      final newEvents = LinkedHashMap<DateTime, List<TrainingSession>>(
        equals: isSameDay,
        hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
      );

      final allMicrocycles = selectedProgram.mesocycles
          .expand((m) => m.microcycles)
          .toList();
      DateTime currentDate = selectedProgram.startDate;

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
    });

// Helper privado para mapear días (puedes moverlo si lo usas en otro lado)
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
