// lib/src/services/training_program_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/athlete/athlete.dart';
import '../models/evaluation.dart';

/// Servicio que genera un programa personalizado sin usar 'Phase'.
/// Usa: Athlete (model), Evaluation (última evaluación opcional), colección 'exercises' y 'injuries' en Firestore.
class TrainingProgramService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera y guarda un programa. Retorna el documento guardado (map con id y contenido).
  /// - [athlete]: objeto Athlete (puedes usar Athlete.fromSnapshot(doc))
  /// - [lastEvaluation]: Evaluation? (última evaluación si existe)
  /// - [forceDurationWeeks]: opcional para forzar duración
  Future<Map<String, dynamic>> generateAndSaveProgram({
    required Athlete athlete,
    Evaluation? lastEvaluation,
    int? forceDurationWeeks,
  }) async {
    // 1) Determinar foco principal (sin usar Phase). Reglas simples:
    final now = DateTime.now();
    String focus = 'Mantenimiento físico';
    if (athlete.hasTournamentSoon && athlete.tournamentDate.isNotEmpty) {
      try {
        final tournamentDate = DateTime.parse(athlete.tournamentDate);
        final weeksToTournament = max(0, tournamentDate.difference(now).inDays ~/ 7);
        if (weeksToTournament <= 2) {
          focus = 'Preparación para torneo';
        } else if (weeksToTournament <= 6) {
          focus = 'Afinamiento (pre-competencia)';
        } else {
          focus = 'Desarrollo general';
        }
      } catch (e) {
        // si parse falla, usar lógica por prioridad
        focus = 'Desarrollo general';
      }
    } else if (athlete.priority.toLowerCase().contains('recuper')) {
      focus = 'Recuperación / Rehabilitación';
    } else {
      // si tests presentes, inferir foco desde resultados
      if (lastEvaluation != null) {
        focus = _inferFocusFromEvaluation(lastEvaluation) ?? 'Desarrollo general';
      }
    }

    // 2) Determinar intensidad a partir de tests (o nivel)
    final intensity = _determineIntensity(athlete, lastEvaluation);

    // 3) Duración y frecuencia (puedes ajustar reglas)
    final durationWeeks = forceDurationWeeks ?? _determineDurationWeeks(focus, athlete.level);
    final weeklyFrequency = _determineWeeklyFrequency(athlete.availability.daysPerWeek);

    // 4) Recopilar tags objetivo desde athlete.goals + evaluation recommendedTags
    final goalTags = <String>{};
    goalTags.addAll(athlete.goals.map((g) => g.toLowerCase()));
    if (lastEvaluation != null) {
      for (final tr in lastEvaluation.tests.values) {
        // si el test categorizó como 'débil' o parecido, consideramos su category
        final cat = (tr.category ?? '').toLowerCase();
        if (cat.isNotEmpty && (cat.contains('débil') || cat.contains('bajo') || cat.contains('regular'))) {
          // intentamos mapear categories a tags; si no, usamos category literal
          goalTags.add(cat);
        }
      }
    }

    // 5) Obtener ejercicios desde Firestore filtrando por nivel y posición preferente
    final exercises = await _fetchRelevantExercises(
      level: athlete.level,
      position: athlete.position,
      includeTags: goalTags.toList(),
      excludeTagsFromInjuries: _collectExcludeTagsFromAthleteInjuries(athlete),
    );

    // 6) Si no hay suficientes ejercicios, rellenar con ejercicios por nivel/posición sin tags
    List<Map<String, dynamic>> selectedExercises = exercises.take(20).toList();
    if (selectedExercises.length < 8) {
      final fallback = await _fetchFallbackExercises(level: athlete.level, position: athlete.position);
      selectedExercises = (selectedExercises + fallback).take(20).toList();
    }

    // 7) Recomendaciones (texto)
    final recommendations = _generateRecommendations(focus, intensity, athlete.injuries);

    // 8) Construir objeto TrainingProgram y guardar en Firestore
    final programDoc = {
      'athleteId': athlete.uid,
      'name': '${athlete.name} - Programa (${focus})',
      'focus': focus,
      'intensity': intensity,
      'durationWeeks': durationWeeks,
      'weeklyFrequency': weeklyFrequency,
      'createdAt': DateTime.now().toIso8601String(),
      'exercises': selectedExercises,
      'recommendations': recommendations,
    };

    final ref = await _db.collection('training_programs').add(programDoc);

    final result = {
      'id': ref.id,
      ...programDoc,
    };

    return result;
  }

  // ---------- Helpers ----------

  String _determineIntensity(Athlete athlete, Evaluation? eval) {
    // Regla sencilla: si nivel explícito "principiante/intermedio/avanzado" usarlo
    final lvl = athlete.level.toLowerCase();
    if (lvl.contains('princip')) return 'baja';
    if (lvl.contains('inter')) return 'media';
    if (lvl.contains('avanz')) return 'alta';

    // Si hay evaluación, calcular promedio relativo de categorías (simple heuristic)
    if (eval != null && eval.tests.isNotEmpty) {
      int lowCount = 0;
      int total = eval.tests.length;
      for (final tr in eval.tests.values) {
        final cat = (tr.category ?? '').toLowerCase();
        if (cat.contains('débil') || cat.contains('bajo')) lowCount++;
      }
      final ratio = total == 0 ? 0.0 : (lowCount / total);
      if (ratio >= 0.6) return 'baja';
      if (ratio >= 0.3) return 'media';
      return 'alta';
    }

    // fallback
    return 'media';
  }

  String? _inferFocusFromEvaluation(Evaluation eval) {
    // Buscar tests con category débil y mapear a foco
    final problemTags = <String>{};
    for (final entry in eval.tests.entries) {
      final testName = entry.key.toLowerCase();
      final tr = entry.value;
      final cat = (tr.category ?? '').toLowerCase();
      if (cat.contains('débil') || cat.contains('bajo')) {
        // heurística básica
        if (testName.contains('salto') || testName.contains('cmj')) problemTags.add('potencia');
        if (testName.contains('sprint') || testName.contains('10m')) problemTags.add('velocidad');
        if (testName.contains('plancha') || testName.contains('core')) problemTags.add('core');
        if (testName.contains('agilidad') || testName.contains('t-test')) problemTags.add('agilidad');
      }
    }

    if (problemTags.contains('potencia')) return 'Mejorar potencia de salto';
    if (problemTags.contains('velocidad')) return 'Mejorar aceleración/velocidad';
    if (problemTags.contains('core')) return 'Fortalecer core y estabilidad';
    if (problemTags.contains('agilidad')) return 'Mejorar agilidad y reacción';

    return null;
  }

  int _determineDurationWeeks(String focus, String level) {
    // Reglas simples
    if (focus.toLowerCase().contains('torneo')) return 2;
    if (focus.toLowerCase().contains('pre') || focus.toLowerCase().contains('potencia')) {
      if (level.toLowerCase().contains('avanz')) return 6;
      return 4;
    }
    if (focus.toLowerCase().contains('recuper')) return 6;
    return 4;
  }

  int _determineWeeklyFrequency(int availableDaysPerWeek) {
    // frecuencia = min(availableDaysPerWeek, 5) por defecto
    return max(1, min(availableDaysPerWeek, 5));
  }

  List<String> _collectExcludeTagsFromAthleteInjuries(Athlete athlete) {
    final excluded = <String>{};
    for (final aInj in athlete.injuries) {
      // AthleteInjury.type corresponde al nombre; intentamos buscar el documento catálogo en 'injuries'
      // Para simplificar (sin seeders), si athlete.injury.type contiene keywords, inferimos tags:
      final t = aInj.type.toLowerCase();
      if (t.contains('hombro')) {
        excluded.addAll(['press', 'heavy_overhead', 'remate', 'bloqueo']);
      }
      if (t.contains('tobillo') || t.contains('esguince')) {
        excluded.addAll(['plyometric', 'jump', 'lateral_speed']);
      }
      if (t.contains('isquiotibial') || t.contains('hamstring')) {
        excluded.addAll(['sprint', 'max_sprint']);
      }
    }
    return excluded.toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRelevantExercises({
    required String level,
    required String position,
    required List<String> includeTags,
    required List<String> excludeTagsFromInjuries,
  }) async {
    // Traer ejercicios por nivel; luego filtramos en memoria por posición y tags
    final snap = await _db.collection('exercises').where('level', isEqualTo: level).get();
    final all = snap.docs.map((d) {
      final m = d.data();
      // añadir id para referencia si hace falta
      m['id'] = d.id;
      return m;
    }).toList();

    // Filtrar por posición (campo positionFocus puede ser 'all' o string)
    final posLower = position.toLowerCase();
    final filteredByPosition = all.where((ex) {
      final pf = (ex['positionFocus'] ?? 'all').toString().toLowerCase();
      return pf == 'all' || pf.contains(posLower) || posLower.contains(pf);
    }).toList();

    // Priorizar ejercicios que contienen includeTags, y excluir por injury tags
    final prioritized = <Map<String, dynamic>>[];
    final secondary = <Map<String, dynamic>>[];

    for (final ex in filteredByPosition) {
      final tags = List<String>.from(ex['tags'] ?? []).map((t) => t.toString().toLowerCase()).toList();

      final excluded = excludeTagsFromInjuries.any((et) => tags.contains(et.toLowerCase()));
      if (excluded) continue;

      final hasGoalTag = includeTags.any((g) => tags.contains(g.toLowerCase()));
      if (hasGoalTag) prioritized.add(ex);
      else secondary.add(ex);
    }

    // mezclar y devolver (prioritized first)
    prioritized.shuffle();
    secondary.shuffle();
    return [...prioritized, ...secondary];
  }

  Future<List<Map<String, dynamic>>> _fetchFallbackExercises({
    required String level,
    required String position,
  }) async {
    final snap = await _db.collection('exercises').where('level', isEqualTo: level).limit(30).get();
    final list = snap.docs.map((d) {
      final m = d.data();
      m['id'] = d.id;
      return m;
    }).toList();
    list.shuffle();
    return list;
  }

  List<String> _generateRecommendations(String focus, String intensity, List<AthleteInjury> injuries) {
    final recs = <String>[];
    recs.add('Focus: $focus');
    recs.add('Mantener intensidad: $intensity');
    if (injuries.isNotEmpty) {
      recs.add('Adaptar ejercicios para lesiones activas y priorizar rehabilitación.');
    }
    if (focus.toLowerCase().contains('torneo')) {
      recs.add('Reducir volumen y mantener intensidad en 7-14 días previos al torneo.');
    }
    recs.add('Incluir al menos 1 sesión de movilidad y 1 de recuperación por semana.');
    return recs;
  }
}
