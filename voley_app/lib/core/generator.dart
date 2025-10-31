// lib/core/generator.dart
import 'package:uuid/uuid.dart';
import 'package:voley_app/src/models/player_profile/player_profile.dart';
import 'package:voley_app/src/models/bd/exercise.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';
import 'package:voley_app/src/models/program/microcicle.dart';
import 'package:voley_app/src/models/program/program.dart';
import 'package:voley_app/src/models/program/training_session.dart';

final _uuid = Uuid();

Program generateProgram(PlayerProfile profile, List<Exercise> allExercises) {
  final now = DateTime.now();

  // buscar próximo torneo
  DateTime? nextTournamentDate;
  if (profile.tournaments.isNotEmpty) {
    final future = profile.tournaments.where((t) => t.date.isAfter(now)).toList();
    if (future.isNotEmpty) {
      future.sort((a, b) => a.date.compareTo(b.date));
      nextTournamentDate = future.first.date;
    }
  }

  final weeksToTournament = nextTournamentDate != null
      ? nextTournamentDate.difference(now).inDays ~/ 7
      : 12; // default 12 semanas si no hay torneo

  // Determinar mesociclos (simple heurística)
  final mesocycles = _createMesocycles(weeksToTournament);

  // Para cada mesociclo, generar microciclos
  for (var m in mesocycles) {
    final microcycles = <Microcycle>[];
    for (int w = 1; w <= m.weeks; w++) {
      final sessions = profile.availability.trainingDays.map((day) {
        final tags = _getTagsForFocus(m.focus, profile);
        final filtered = _filterExercises(allExercises, tags, profile);

        return TrainingSession(
          day: day,
          objective: m.focus,
          load: _calculateSessionLoad(m.focus, profile),
          exercises: filtered.take(5).toList(),
        );
      }).toList();

      microcycles.add(Microcycle(weekNumber: w, sessions: sessions));
    }
    // reemplazar con nuevos microcycles (inmutable replace)
    final index = mesocycles.indexOf(m);
    mesocycles[index] = Mesocycle(
      name: m.name,
      weeks: m.weeks,
      focus: m.focus,
      progressionType: m.progressionType,
      microcycles: microcycles,
    );
  }

  final program = Program(
    id: _uuid.v4(),
    source: 'Automático',
    startDate: now,
    endDate: now.add(Duration(days: weeksToTournament * 7)),
    mesocycles: mesocycles,
  );

  return program;
}

List<Mesocycle> _createMesocycles(int totalWeeks) {
  if (totalWeeks <= 6) {
    return [
      Mesocycle(
        name: 'Potencia',
        weeks: totalWeeks.clamp(1, 6),
        focus: 'Potencia',
        progressionType: 'lineal',
        microcycles: [],
      ),
    ];
  }

  // heurística simple: repartir en bloques de 3-5 semanas
  final baseWeeks = (totalWeeks * 0.4).round().clamp(3, 8);
  final strengthWeeks = (totalWeeks * 0.35).round().clamp(3, 8);
  final powerWeeks = (totalWeeks - baseWeeks - strengthWeeks).clamp(2, 6);

  return [
    Mesocycle(name: 'Base', weeks: baseWeeks, focus: 'Base', progressionType: 'lineal', microcycles: []),
    Mesocycle(name: 'Fuerza', weeks: strengthWeeks, focus: 'Fuerza', progressionType: 'progresiva', microcycles: []),
    Mesocycle(name: 'Potencia', weeks: powerWeeks, focus: 'Potencia', progressionType: 'ondulante', microcycles: []),
  ];
}

List<Exercise> _filterExercises(List<Exercise> all, List<String> tags, PlayerProfile profile) {
  // filtrar por tags, nivel (nivel aproximado), y contraindicaciones
  final levelKey = profile.level.toLowerCase(); // mapear si hace falta
  final filtered = all.where((e) {
    final hasTag = e.tags.any((t) => tags.contains(t));
    final matchesLevel = _normalizeLevel(e.level) <= _normalizeLevel(levelKey);
    final notContra = e.contraindicatedFor.every((c) => !profile.injuries.contains(c));
    return hasTag && matchesLevel && notContra;
  }).toList();

  // ordenar por cuantas tags coinciden (priorizar)
  filtered.sort((a, b) {
    final aMatch = a.tags.where((t) => tags.contains(t)).length;
    final bMatch = b.tags.where((t) => tags.contains(t)).length;
    return bMatch.compareTo(aMatch);
  });

  return filtered;
}

int _normalizeLevel(String level) {
  final s = level.toLowerCase();
  if (s.contains('principiante') || s.contains('recreativo')) return 1;
  if (s.contains('intermedio') || s.contains('competitivo')) return 2;
  return 3; // avanzado
}

List<String> _getTagsForFocus(String focus, PlayerProfile profile) {
  final lower = focus.toLowerCase();
  final result = <String>[];

  if (lower.contains('base')) {
    result.addAll(['movilidad', 'core', 'fuerza general', 'resistencia']);
  } else if (lower.contains('fuerza')) {
    result.addAll(['fuerza', 'estabilidad', 'rodilla', 'técnica fuerza']);
  } else if (lower.contains('potencia')) {
    result.addAll(['salto', 'explosivo', 'plyo', 'velocidad']);
  } else {
    result.addAll(profile.goals.map((g) => g.toLowerCase()));
  }

  // incluir debilidades detectadas en la evaluación
  for (var w in profile.evaluation.weaknesses) {
    if (!result.contains(w.toLowerCase())) result.add(w.toLowerCase());
  }

  return result;
}

double _calculateSessionLoad(String focus, PlayerProfile profile) {
  // simple heurística: base=0.6, fuerza=0.8, potencia=1.0
  final f = focus.toLowerCase();
  double base = 0.6;
  if (f.contains('fuerza')) base = 0.8;
  if (f.contains('potencia')) base = 1.0;
  // ajustar por nivel: semiprofesional tolera más
  final level = profile.level.toLowerCase();
  if (level.contains('semiprofesional')) base *= 1.05;
  if (level.contains('recreativo')) base *= 0.9;
  return double.parse(base.toStringAsFixed(2));
}
