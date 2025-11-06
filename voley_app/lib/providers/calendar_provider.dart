import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';
import 'package:voley_app/providers/providers.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart'; // playerProgramsProvider

// --- Selección del programa activo del jugador ---
class SelectedProgramNotifier extends Notifier<Program?> {
  Program? _lastSelected;

  @override
  Program? build() {
    final programsAsync = ref.watch(playerProgramsProvider);
    return programsAsync.when(
      loading: () => _lastSelected,
      error: (e, s) => _lastSelected,
      data: (programs) {
        if (programs.isEmpty) {
          _lastSelected = null;
          return null;
        }
        if (_lastSelected == null ||
            !programs.any((p) => p.id == _lastSelected!.id)) {
          _lastSelected = programs.first;
        }
        return _lastSelected;
      },
    );
  }

  void selectProgram(Program newProgram) {
    _lastSelected = newProgram;
    state = newProgram;
  }
}

final selectedProgramProvider =
    NotifierProvider<SelectedProgramNotifier, Program?>(SelectedProgramNotifier.new);

// --- Eventos para TableCalendar: Map<DateTime, List<TrainingSession>> ---
final calendarEventsProvider =
    Provider<LinkedHashMap<DateTime, List<TrainingSession>>>((ref) {
  final selectedProgram = ref.watch(selectedProgramProvider);
  if (selectedProgram == null) {
    return LinkedHashMap<DateTime, List<TrainingSession>>(
      equals: isSameDay,
      hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
    );
  }

  final map = LinkedHashMap<DateTime, List<TrainingSession>>(
    equals: isSameDay,
    hashCode: (key) => key.day * 1000000 + key.month * 10000 + key.year,
  );

  // Flatea todos los microciclos
  final microcycles = selectedProgram.mesocycles.expand((m) => m.microcycles).toList();
  DateTime currentWeekStart = selectedProgram.startDate;

  for (final micro in microcycles) {
    // Semana de 7 días desde currentWeekStart
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = currentWeekStart.add(Duration(days: dayOffset));
      final normalizedDate = DateTime(date.year, date.month, date.day);

      final dayEnum = _weekdayToEnum(date.weekday);
      final sessionsForDay = micro.sessions.where((s) => s.day == dayEnum).toList();

      if (sessionsForDay.isNotEmpty) {
        map.putIfAbsent(normalizedDate, () => []).addAll(sessionsForDay);
      }
    }
    // Avanza a la siguiente semana
    currentWeekStart = currentWeekStart.add(const Duration(days: 7));
  }

  return map;
});

// Día de inicio/fin visibles del calendario
final calendarFocusedDayProvider = StateProvider<DateTime>((_) => DateTime.now());
final calendarRangeProvider = Provider<CalendarFormat>((_) => CalendarFormat.month);

// Helpers
DayOfWeek _weekdayToEnum(int weekday) {
  // DateTime.weekday: 1=Mon ... 7=Sun
  switch (weekday) {
    case DateTime.monday:
      return DayOfWeek.mon;
    case DateTime.tuesday:
      return DayOfWeek.tue;
    case DateTime.wednesday:
      return DayOfWeek.wed;
    case DateTime.thursday:
      return DayOfWeek.thu;
    case DateTime.friday:
      return DayOfWeek.fri;
    case DateTime.saturday:
      return DayOfWeek.sat;
    case DateTime.sunday:
    default:
      return DayOfWeek.sun;
  }
}
